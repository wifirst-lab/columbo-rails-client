# Columbo Rails client

This gem provides Rails integrations for Columbo:

* easily plugable to ActiveModel and automatically crafts the
  Columbo payload.
* offers to your models a way to publish events to Columbo.
* automatic publishings hooked on ActiveRecord Callbacks.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'columbo-rails-client'
```

And then execute:
```bash
$ bundle
```

## Configuration

`columbo-rails-client` uses `columbo-ruby-client` gem for configuration. See the advanced configuration of the latest [here](https://github.com/wifirst-lab/columbo-ruby-client).

For the next examples, the Columbo client is initiliazed like this:

```ruby
# config/initializers/columbo.rb

Columbo.configure do |config|
  config.system.uid = 'crm.my-company.com'
  config.system.label = "My Company's CRM"
  config.system.type = 'CRM'

  config.client = Columbo::Client::HTTP.new('http://my-company.com/push')
end
```

## Usage

### Simplest examples

#### Minimal code for publication

In each model you want to activate event publication, you must at least:

* include module `Columbo::Resource`
* define the `columbo_actor` method which returns a `Hash` with {:uid, :type, :label} keys.

```ruby
# app/models/contract.rb

class Contract < ApplicationRecord
  include Columbo::Resource

  def columbo_actor
    { uid: 34, type: "commercial", label: "commercial@my-company.com" }
  end
end
```

The next snippet:

```ruby
c = Contract.new(signed: false)
c.sign!

# Publish an event of type "contract.signed"
c.columbo.publish('signed')
```

will publish the next event:

```json
{
  "system": {
    "uid": "crm.my-company.com",
    "label": "My Company's CRM",
    "type": "CRM"
  },
  "actor": {
    "uid": 34,
    "label": "commercial@my-company.com",
    "type": "commercial"
  },
  "resource": {
    "uid": 1,
    "type": "contract",
    "label": "contract#1",
    "attributes": {
      "id": 1,
      "signed": true,
      "created_at": "2017-01-03T13:08:28.429Z",
      "updated_at": "2017-01-03T13:08:28.429Z"
    }
  },
  "related_resources": null,
  "timestamp": "2017-01-03T13:16:32Z",
  "action": "contract.signed"
}
```

The `publish` method returns `true` or `false` if the operation succeeded or not. You can also use the `publish!` method if you want to raise an error if the operation fails.

##### Note on AMQP client

If you use the AMQP client, the `publish` method accepts a second option parameter which fits the options `Hash` understable by `Bunny` gem. Values for these options are available [here](http://reference.rubybunny.info/Bunny/Exchange.html#publish-instance_method).

For example, the default `routing_key` for the previous event shown above is 'contract.signed' (equal to the action). You could override the `routing_key` by giving it as an option entry in the `publish` method:

```ruby
c.columbo.publish('signed', routing_key: 'contract.approved')
```

#### Automatic callbacks

You can include `Columbo::Resource::Callbacks` in your models to
automatically hook publishings on the next three Rails callbacks :

* `create`
* `update`
* `destroy`

For example, for the next model:

```ruby
class Contract < ApplicationRecord
  include Columbo::Resource
  include Columbo::Resource::Callbacks
end
```

Respectively on `after_create`, `after_update` and `after_destroy` callbacks, any `Contract` record will publish an event with these actions names:

* `contract.created`
* `contract.updated`
* `contract.destroyed`

### Override default values of the event payload

#### Override at the instance level

As seen above, the event is automatically crafted from the model included the `Columbo::Resource` module. You can override some parts of the crafted event by implemented in your model:

* `columbo_payload`  method to override the attributes of the resource.
* `columbo_resource_label` method to override the label of the resource.
* `columbo_related_resources` method to override the related resources array.

```ruby
class Contract < ApplicationRecord

  include Columbo::Resource
  include Columbo::Resource::Callbacks

  has_one :client

  # This method is called to create the attributes of the resources Columbo event hash.
  # It should return a hash which fits the mapping you provided to Columbo for this resource.
  # Here we add an extra info attribute to the payload sent to Columbo
  def columbo_payload
    as_json.merge({ client: client.id })
  end

  # this method is called to override the label of the resource Columbo event.
  def columbo_resource_label
    if signed?
      'Unsigned contract'
    else
      'Signed contract'
    end
  end

  # this method is called to create the related_resources array
  def related_resources
    [{ uid: client.id, type: 'client' }]
  end

  # compulsory method, see the previous example
  def columbo_actor
    { uid: 34, type: "commercial", label: "commercial@my-company.com" }
  end
end
```

The next snippet:

```ruby
Contract.create(signed: false, client: Client.find(4))
```

will publish the next event:

```json
{
  "system": {
    "uid": "crm.my-company.com",
    "label": "My Company's CRM",
    "type": "CRM"
  },
  "actor": {
    "uid": 34,
    "type": "commercial",
    "label": "commercial@my-company.com"
  },
  "resource": {
    "uid": 3,
    "type": "contract",
    "label": "Unsigned contract",
    "attributes": {
      "id": 3,
      "signed": false,
      "created_at": "2017-01-03T13:08:28.429Z",
      "updated_at": "2017-01-03T13:08:28.429Z",
      "client": 4
    }
  },
  "related_resources": [{"uid": 5, "type": "commercial_office"}],
  "timestamp": "2017-01-03T15:57:37Z",
  "action": "contract.created"
}
```

#### Override at publish time

`publish` and `publish!` methods can take a block as 3rd parameter to locally override a part of the event Columbo payload. The next table gathers all parts of the payload you can override:

|Name |Expected values|
|---- |---------------|
|actor| Hash with 3 keys: (:uid, :label, :type)|
|system| Hash with 3 keys: (:uid, :label, :type)|
|resource| Hash with one of these keys: (:uid, :label, :type, :attributes)|
|related_resources|Array of Hash with 2 keys: (:uid, :type) or nil|
|action| the action name (string)|
|timestamp| DateTime in  [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) string format (UTC)|

The next snippet:

```ruby
c = Contract.find(3)
c.complete!

c.columbo.publish 'completed' do |info|
  info.system = { uid: 'accounting.my-company.com', label: "My Company's Accounting", type: 'Accounting' }
  info.actor = { uid: 30, label: 'accountant@my-company.com', type: 'accountant'}
end
```

will publish the next event:

```json
{
  "system": {
    "uid": "accounting.my-company.com",
    "label": "My Company's Accounting",
    "type": "Accounting"
  },
  "actor": {
    "uid": 30,
    "label": "accountant@my-company.com",
    "type": "accountant"
  },
  "resource": {
    "uid": 3,
    "type": "contract",
    "label": "Signed contract",
    "client": 7,
    "attributes": {
      "id": 3,
      "signed": true,
      "created_at": "2017-01-03T13:08:28.429Z",
      "updated_at": "2017-01-03T13:08:28.429Z"
    }
  },
  "related_resources": [{"uid": 5, "type": "commercial_office"}],
  "timestamp": "2017-01-03T15:51:49Z",
  "action": "contract.completed"
}
```

You can still pass `options` to the publisher:

```ruby
c = Contract.create(signed: false)

c.columbo.publish 'completed', routing_key: 'contract.closed' do |info|
  info.system = { uid: 'accounting.my-company.com', label: "My Company's Accounting", type: 'Accounting' }
  info.actor = { uid: 30, label: 'accountant@my-company.com', type: 'accountant'}
end
```

## Test your app with this gem

### With Rspec

Mock calls to publish and publish! methods with :

```ruby
allow_any_instance_of(Columbo::Resource::Publisher).to receive(:publish)
allow_any_instance_of(Columbo::Resource::Publisher).to receive(:publish!)
```
