require 'yaml'
require 'active_support/core_ext/hash/indifferent_access'

class SettingsAccessor
  def initialize(yaml)
    @hash = YAML.load(yaml).with_indifferent_access
  end

  def sender_email_address
    @hash[:sender_email_address]
  end

  def kochiku_notifications_email_address
    @hash[:kochiku_notifications_email_address]
  end

  def domain_name
    @hash[:domain_name]
  end

  def kochiku_protocol
    @hash[:use_https] ? "https" : "http"
  end

  def kochiku_host
    @hash[:kochiku_host]
  end

  def kochiku_host_with_protocol
    "#{kochiku_protocol}://#{kochiku_host}"
  end

  def stash
    @hash.fetch(:stash, {})
  end

  def stash_host
    stash[:host]
  end

  def stash_username
    stash[:username]
  end

  def stash_password_file
    file = Pathname.new(stash[:password_file])
    if file.relative?
      File.join(File.expand_path('../..', __FILE__), file)
    else
      file
    end.to_s
  end

  def smtp_server
    @hash[:smtp_server]
  end

  def git_mirror
    @hash[:git_mirror]
  end

  def git_pair_email_prefix
    @hash[:git_pair_email_prefix]
  end

  def github_hosts
    # TODO: Upgrade our config and remove this Square-specific default.
    @hash.fetch(:github_hosts, %w(git.squareup.com github.com))
  end
end
