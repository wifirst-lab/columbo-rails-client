class SimplePublishing
  attr_accessor :id, :name

  def initialize(name)
    @id = 1
    @name = name
  end

  def columbo_actor
    {uid: 1, label: 'label', type: 'simple'}
  end

  def as_json
    {id: @id, name: @name}
  end
end

class PublishingWithNoActor
  include Columbo::Resource

  attr_accessor :id, :name

  def initialize(name)
    @id = 1
    @name = name
  end

  def as_json
    {id: @id, name: @name}
  end
end

class PublishingWithOverride
  include Columbo::Resource

  attr_accessor :id, :name

  def initialize(name)
    @id = 1
    @name = name
  end

  def columbo_payload
    as_json.merge({message: 'automatically added by columbo resource'})
  end

  def columbo_resource_label
    'columbo resource label override'
  end

  def columbo_actor
    {uid: 1, label: 'label', type: 'simple'}
  end

  def as_json
    {id: @id, name: @name}
  end
end
