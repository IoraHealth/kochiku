require 'spec_helper'

describe RemoteServer::Github do
  describe '#promote_branch!' do
    let(:repo) { double(project_params: {}) }
    let(:server) { described_class.new(repo) }

    it 'creates branch if it does not exist' do
      GithubRequest.should_receive(:post).with do |uri, args|
        args[:ref] == 'refs/heads/deployable-myapp' &&
          args[:sha] == 'abc123'
      end
      GithubRequest.should_receive(:patch).with do |uri, args|
        uri.to_s.should =~ /deployable-myapp\Z/ &&
          args[:force] == "true" &&
          args[:sha] == 'abc123'
      end
      server.promote_branch!('deployable-myapp', 'abc123')
    end

    it 'updates branch to the given ref when it already exists' do
      GithubRequest
        .should_receive(:post)
        .and_raise(GithubRequest::ResponseError)
      GithubRequest.should_receive(:patch).with do |uri, args|
        uri.to_s.should =~ /deployable-myapp\Z/ &&
          args[:force] == "true" &&
          args[:sha] == 'abc123'
      end
      server.promote_branch!('deployable-myapp', 'abc123')
    end
  end

  describe '.project_params' do
    it 'raises UnknownUrl for invalid urls' do
      # This is current behaviour, though if you want to add support for it
      # that would be cool.
      expect { described_class.project_params \
        "https://github.com/blah"
      }.to raise_error(UnknownUrl)
    end
  end
end
