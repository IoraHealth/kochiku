class Repository < ActiveRecord::Base
  UnknownServer = Class.new(RuntimeError)

  has_many :projects, :dependent => :destroy
  validates_presence_of :url
  validates_numericality_of :timeout, :only_integer => true
  validates_inclusion_of :timeout, :in => 0..1440

  def remote_server
    self.class.remote_server(url).new(self)
  end

  def main_project
    projects.where(name: repository_name).first
  end

  delegate :base_html_url, :base_api_url, to: :remote_server

  # Where to fetch from (git mirror if defined, otherwise the regular git url)
  def url_for_fetching
    if Settings.git_mirror.present?
      url.gsub(%r{(git@|https://).*?(:|/)}, Settings.git_mirror)
    else
      url
    end
  end

  def repository_name
    project_params[:repository]
  end

  def repo_cache_name
    repo_cache_dir || "#{repository_name}-cache"
  end

  def promotion_refs
    on_green_update.split(",").map(&:strip).reject(&:blank?)
  end

  def interested_github_events
    event_types = ['pull_request']
    event_types << 'push' if run_ci
    event_types
  end

  def self.remote_server(url)
    server = [
      RemoteServer::Stash,
      RemoteServer::Github
    ].find {|x| x.match?(url) }

    raise UnknownServer, url unless server

    server
  end

  # This is ugly. Is there a better way?
  def self.convert_to_ssh_url(url)
    params = Repository.project_params(url)

    remote_server(url).convert_to_ssh_url(params)
  end

  def has_on_success_script?
    on_success_script.to_s.strip.present?
  end

  def has_on_success_note?
    on_success_note.to_s.strip.present?
  end

  def ci_queue_name
    queue_override.presence || "ci"
  end

  def project_params
    Repository.project_params(url)
  end

  private

  def self.project_params(url)
    remote_server(url).project_params(url)
  end
end
