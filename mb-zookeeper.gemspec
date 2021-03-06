$:.push File.expand_path("../lib", __FILE__)
require 'zookeeper/version'

Gem::Specification.new do |s|
  s.name = %q{mb-zookeeper}
  s.version = Zookeeper::VERSION
  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Shane Mingins", "Topper Bowers"]
  s.date = %q{2010-05-19}
  s.description = %q{A Ruby client interface to the Java ZooKeeper server.}
  s.email = %q{topper@toppingdesign.com}
  s.extra_rdoc_files = ["README"]

  s.files = ["README", "lib/zookeeper.rb", "lib/zookeeper/acl.rb", "lib/zookeeper/id.rb", "lib/zookeeper/keeper_exception.rb",
            "lib/zookeeper/permission.rb", "lib/zookeeper/stat.rb", "lib/zookeeper/watcher_event.rb", "lib/zookeeper/connection_pool.rb",
            "lib/zookeeper/event_handler.rb",  "lib/zookeeper/event_handler_subscription.rb", "lib/zookeeper/locker.rb", "lib/zookeeper/message_queue.rb", "lib/zookeeper/logging.rb"]
    
  case RUBY_PLATFORM
  when /java/
     s.files += ["ext/zookeeper_j/log4j-1.2.15.jar", "ext/zookeeper_j/zookeeper-3.3.1.jar",
                 "ext/zookeeper_j/extensions.rb", "ext/zookeeper_j/zookeeper.rb"]
     s.platform = 'java'
  else
     s.files += ["ext/zookeeper_c/zookeeper_ruby.c", "ext/zookeeper_c/zookeeper.rb", "ext/zookeeper_c/zkc-3.3.1.tar.gz"]
     s.extensions = ["ext/zookeeper_c/extconf.rb"]
  end

  s.homepage = %q{http://github.com/tobowers/zookeeper/tree/master}

  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "ZooKeeper", "--main", "README"]
  s.require_paths = ["lib", "ext"]
  s.rubygems_version = %q{1.1.0}
  s.summary =  %q{A Ruby client interface to the Java ZooKeeper server.}

  s.add_development_dependency "rspec", ">=2.0.0"

  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
end

