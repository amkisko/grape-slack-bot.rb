require 'spec_helper'

describe SlackBot::Logger do
  describe '#info' do
    it 'prints the args' do
      expect { subject.info('test') }.to output(%(["test"]\n)).to_stdout
    end

    it 'prints the kwargs' do
      expect { subject.info(test: 'test') }.to output(%({:test=>"test"}\n)).to_stdout
    end
  end
end
