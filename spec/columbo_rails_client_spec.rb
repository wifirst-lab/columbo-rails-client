require 'spec_helper'
require 'mock_models'

class String
  def underscore
    self.gsub(/([A-Z])/, '_\1').downcase[1..-1]
  end
end

RSpec.describe Columbo do
  it 'has a version number' do
    expect(Columbo::VERSION).not_to be nil
  end

  context(:simple_publishing) do
    it 'resource attributes payload part' do
      dummer = SimplePublishing.new('dummy')
      publisher = Columbo::Resource::Publisher.new(dummer)
      publisher.instance_variable_set('@payload', OpenStruct.new(resource: {}))

      expect(publisher.send(:resource)[:attributes][:id]).to eq(1)
      expect(publisher.send(:resource)[:attributes][:name]).to eq('dummy')
      expect(publisher.send(:resource)[:attributes][:message]).to eq(nil)
    end
  end

  context(:failing_publishing) do
    it 'publishing should raise with no actor given' do
      dummer = PublishingWithNoActor.new(name: 'dummy')
      expect { dummer.columbo.publish!('educated') }.to raise_error(NoMethodError)
    end
  end


  context(:overriding) do

    context(:publishing_with_overriding) do
      it 'attributes resource is override' do
        dummer = PublishingWithOverride.new('dummy')
        publisher = Columbo::Resource::Publisher.new(dummer)
        publisher.instance_variable_set('@payload', OpenStruct.new(resource: {}))

        expect(publisher.send(:resource)[:uid]).to eq(1)
        expect(publisher.send(:resource)[:type]).to eq('publishing_with_override')
        expect(publisher.send(:resource)[:label]).to eq('columbo resource label override')
        expect(publisher.send(:resource)[:attributes][:id]).to eq(1)
        expect(publisher.send(:resource)[:attributes][:name]).to eq('dummy')
        expect(publisher.send(:resource)[:attributes][:message]).to eq('automatically added by columbo resource')
      end
    end

    context(:publishing_with_local_overriding) do
      it 'should take value in publish block to make the payload' do
        dummer = PublishingWithOverride.new('dummy')
        publisher = Columbo::Resource::Publisher.new(dummer)

        allow_message_expectations_on_nil
        expect(Columbo.client).to receive(:publish).with(
                                    {
                                      system: {
                                        uid:'local_system_uid', label: 'local_system_label', type: 'local_system_type'
                                      },
                                      actor: {
                                        uid: 30, label: 'local dummer label', type: 'local dummer type'
                                      },
                                      resource: {
                                        uid: 1,
                                        type: 'local dummer',
                                        label: 'local label',
                                        attributes: {
                                          id: 1,
                                          name: 'dummy',
                                          message: 'local message'
                                        }
                                      },
                                      related_resources: nil,
                                      timestamp: '2017-01-01T00:00:00Z',
                                      action: 'dummer.test'
                                    },
                                    {}
                                  ).and_return(nil)

        dummer.columbo.publish! 'test' do |payload|
          payload.system = {:uid=>'local_system_uid', :label=>'local_system_label', :type=>'local_system_type'}
          payload.actor = {:uid=>30, :label=>'local dummer label', :type=>'local dummer type'}
          payload.resource = {uid: 1, type: 'local dummer', label: 'local label', attributes: dummer.as_json.merge(message: 'local message')}
          payload.timestamp = '2017-01-01T00:00:00Z'
          payload.action = 'dummer.test'
        end
      end
    end
  end
end
