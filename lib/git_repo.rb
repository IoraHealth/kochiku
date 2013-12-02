require 'cocaine'
require 'fileutils'

class GitRepo
  class RefNotFoundError < StandardError; end
  class RemoteDoesNotMatch < StandardError; end

  WORKING_DIR = Rails.root.join('tmp', 'build-partition')

  class << self
    def inside_copy(repository, sha, branch = "master")
      cached_repo_path = cached_repo_for(repository)

      synchronize_cache_repo(cached_repo_path, branch)

      Dir.mktmpdir(nil, WORKING_DIR) do |dir|
        # clone local repo (fast!)
        run! "git clone #{cached_repo_path} #{dir}"

        Dir.chdir(dir) do
          raise RefNotFoundError, "repo:#{repository.url} branch:#{branch}, sha:#{sha}" unless system("git rev-list --quiet -n1 #{sha}")

          run! "git checkout --quiet #{sha}"

          run! "git submodule --quiet init"
          # redirect the submodules to the cached_repo
          submodules = `git config --get-regexp "^submodule\\..*\\.url$"`
          submodules.each_line do |config_line|
            submodule_path = config_line.match(/submodule\.(.*?)\.url/)[1]
            `git config --replace-all submodule.#{submodule_path}.url "#{cached_repo_path}/#{submodule_path}"`
          end

          run! "git submodule --quiet update"

          yield dir
        end
      end
    end

    def sha_for_branch(repo, branch)
      repo.remote_server.sha_for_branch(branch)
    end

    def inside_repo(repository)
      cached_repo_path = cached_repo_for(repository)

      Dir.chdir(cached_repo_path) do
        synchronize_with_remote('origin')

        yield
      end
    end

    def create_working_dir
      FileUtils.mkdir_p(WORKING_DIR)
    end

    private

    def cached_repo_for(repository)
      cached_repo_path = File.join(WORKING_DIR, repository.repo_cache_name)

      if !File.directory?(cached_repo_path)
        clone_repo(repository, cached_repo_path)
      end

      Dir.chdir(cached_repo_path) do
        remote_url = Cocaine::CommandLine.new("git config --get remote.origin.url").run.chomp
        if remote_url != repository.url
          Rails.logger.info "#{remote_url.inspect} does not match #{repository.url.inspect}."
          raise RemoteDoesNotMatch
        end
      end

      cached_repo_path
    rescue RemoteDoesNotMatch
      FileUtils.rm_rf(cached_repo_path)
      retry
    end

    def synchronize_cache_repo(cached_repo_path, branch)
      Dir.chdir(cached_repo_path) do
        # update the cached repo
        synchronize_with_remote('origin', branch)
        Cocaine::CommandLine.new("git submodule update", "--init --quiet").run
      end
    end

    def run!(cmd)
      unless system(cmd)
        raise "non-0 exit code #{$?} returned from [#{cmd}]"
      end
    end

    def clone_repo(repo, cached_repo_path)
      # Note: the -c option is not available on git 1.7.x
      Cocaine::CommandLine.new(
          "git clone",
          "--recursive -c remote.origin.pushurl=#{repo.url} #{repo.url_for_fetching} #{cached_repo_path}").
          run
    end

    def synchronize_with_remote(name, branch = nil)
      refspec = branch.to_s.empty? ? "" : "+#{branch}"
      # Undo this for now, partition does not seem as stable with this enabled.
      #Cocaine::CommandLine.new("git fetch", "--quiet --prune --no-tags #{name} #{refspec}").run
      Cocaine::CommandLine.new("git fetch", "--quiet --prune --no-tags #{name}").run
    rescue Cocaine::ExitStatusError
      # likely caused by another 'git fetch' that is currently in progress. Wait a few seconds and try again
      tries = (tries || 0) + 1
      if tries < 2
        sleep 15
        retry
      end
    end
  end
end
