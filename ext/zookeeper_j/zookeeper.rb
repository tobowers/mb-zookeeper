include Java

require 'zookeeper_j/zookeeper-3.3.1.jar'
require 'zookeeper_j/log4j-1.2.15.jar'
require 'zookeeper_j/extensions'

JZooKeeper = org.apache.zookeeper.ZooKeeper
ZooDefs = org.apache.zookeeper.ZooDefs

class ZooKeeper < JZooKeeper
  class JavaSilentWatcher
    import org.apache.zookeeper.Watcher
    def process(event)
    end
  end

  attr_accessor :watcher

  # Initialize a new ZooKeeper Client.  Can be initialized with a string of the hosts names (see :host argument) otherwise pass a hash with arguments set.
  # 
  # ==== Arguments
  # * <tt>:host</tt> -- string of comma separated ZooKeeper server host:port pairs e.g. "server1:3000, server2:3000"
  # * <tt>:timeout</tt> -- optional session timeout, if not passed default will be used
  # * <tt>:watcher</tt> -- optional object implementing Watcher interface otherwise DefaultWatcher is used
  # 
  # ==== Examples
  #   zk = ZooKeeper.new("localhost:2181")
  #   zk = ZooKeeper.new("localhost:2181,localhost:3000")
  #   zk = ZooKeeper.new(:host => "localhost:2181", :watcher => MyWatcher.new)
  #   zk = ZooKeeper.new(:host => "localhost:2181,localhost:3000", :timeout => 10000, :watcher => MyWatcher.new)
  def initialize(host, args = {})
    timeout = args[:timeout] || DEFAULTS[:timeout]
    @watcher =
        if args[:watcher] == :default
          EventHandler.new(self)
        else
          args[:watcher] || JavaSilentWatcher.new
        end
    @watcher.extend Zk::Watcher
    super(host, timeout, @watcher)
  end
  
  # Returns if ZooKeeper is in the closed state
  def closed?
    getState() == States::CLOSED
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end
  
  # Returns if ZooKeeper is in the connected state
  def connected?
    getState() == States::CONNECTED
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end
  
  # Create a node with the given path. The node data will be the given data, and node acl will be the given acl.  The path is returned.
  # 
  # The ephemeral argument specifies whether the created node will be ephemeral or not.
  # 
  # An ephemeral node will be removed by the ZooKeeper automatically when the session associated with the creation of the node expires.
  # 
  # The sequence argument can also specify to create a sequential node. The actual path name of a sequential node will be the given path plus a suffix "_i" where i is the 
  # current sequential number of the node. Once such a node is created, the sequential number will be incremented by one.
  # 
  # If a node with the same actual path already exists in the ZooKeeper, a KeeperException with error code KeeperException::NodeExists will be thrown. Note that since 
  # a different actual path is used for each invocation of creating sequential node with the same path argument, the call will never throw a NodeExists KeeperException.
  # 
  # If the parent node does not exist in the ZooKeeper, a KeeperException with error code KeeperException::NoNode will be thrown.
  # 
  # An ephemeral node cannot have children. If the parent node of the given path is ephemeral, a KeeperException with error code KeeperException::NoChildrenForEphemerals 
  # will be thrown.
  # 
  # This operation, if successful, will trigger all the watches left on the node of the given path by exists and get API calls, and the watches left on the parent node 
  # by children API calls.
  # 
  # If a node is created successfully, the ZooKeeper server will trigger the watches on the path left by exists calls, and the watches on the parent of the node by children calls.
  #
  # Called with a hash of arguments set.  Supports being executed asynchronousy by passing a callback object.
  # 
  # ==== Arguments
  # * <tt>path</tt> -- path of the node
  # * <tt>data</tt> -- initial data for the node
  # * <tt>:acl</tt> -- defaults to ACL::OPEN_ACL_UNSAFE, otherwise the ACL for the node
  # * <tt>:ephemeral</tt> -- defaults to false, if set to true the created node will be ephemeral
  # * <tt>:sequence</tt> -- defaults to false, if set to true the created node will be sequential
  # * <tt>:callback</tt> -- provide a AsyncCallback::StringCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  # 
  # ==== Examples
  # ===== create node, ACL will default to ACL::OPEN_ACL_UNSAFE
  #   zk.create(:path => "/path", "foo")
  #   # => "/path"
  #
  # ===== create ephemeral node
  #   zk.create("/path", :mode => :ephemeral)
  #   # => "/path"
  #
  # ===== create sequential node
  #   zk.create("/path", :mode => :persistent_sequence)
  #   # => "/path0"
  #
  # ===== create ephemeral and sequential node
  #   zk.create("/path", "foo", :mode => :ephemeral_sequence)
  #   # => "/path0"
  #
  # ===== create a child path
  #   zk.create("/path/child", "bar")
  #   # => "/path/child"
  #
  # ===== create a sequential child path
  #   zk.create("/path/child", "bar", :mode => :ephemeral_sequence)
  #   # => "/path/child0"
  #
  # ===== create asynchronously with callback object
  #
  #   class StringCallback
  #     def process_result(return_code, path, context, name)
  #       # do processing here
  #     end
  #   end
  #  
  #   callback = StringCallback.new
  #   context = Object.new
  #
  #   zk.create("/path", "foo", :callback => callback, :context => context)
  #
  # ===== create asynchronously with callback proc
  #
  #   callback = proc do |return_code, path, context, name|
  #       # do processing here
  #   end
  #
  #   context = Object.new
  #
  #   zk.create("/path", "foo", :callback => callback, :context => context)
  #
  # 
  def create(path, data = "", args = {})
    data = data || ""
    args = args || {}
    acls     = args[:acl] || ZooKeeper::ACL::OPEN_ACL_UNSAFE
    callback = args[:callback]
    context  = args[:context]
    mode     = args[:mode] || :ephemeral

    java_acls = acls.collect{|acl| Zk::ACL.to_java(acl)}
    java_mode = Zk::CreateMode.to_java(mode)

    if callback
      callback.extend Zk::AsyncCallback::StringCallback unless callback.is_a?(Proc) || callback.respond_to?(:processResult)
      super(path, data.to_java_bytes, java_acls, java_mode, callback, context)
    else
      super(path, data.to_java_bytes, java_acls, java_mode)
    end
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end

  # Return the data and stat of the node of the given path.  
  # 
  # If the watch is true and the call is successfull (no exception is thrown), a watch will be left on the node with the given path. The watch will be triggered by a 
  # successful operation that sets data on the node, or deletes the node.
  # 
  # A KeeperException with error code KeeperException::NoNode will be thrown if no node with the given path exists.
  # 
  # Can be called with just the path, otherwise a hash with the arguments set.  Supports being executed asynchronousy by passing a callback object.
  # 
  # ==== Arguments
  # * <tt>path</tt> -- path of the node
  # * <tt>:watch</tt> -- defaults to false, set to true if you need to watch this node
  # * <tt>:callback</tt> -- provide a AsyncCallback::DataCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  # 
  # ==== Examples
  # ===== get data for path
  #   zk.get("/path")
  #   
  # ===== get data and set watch on node
  #   zk.get("/path", :watch => true)
  #
  # ===== get data asynchronously
  #
  #   class DataCallback
  #     def process_result(return_code, path, context, data, stat)
  #       # do processing here
  #     end
  #   end
  #
  #   zk.get("/path") do |return_code, path, context, data, stat|
  #     # do processing here
  #   end
  #  
  #   callback = DataCallback.new
  #   context = Object.new
  #   zk.get("/path", :callback => callback, :context => context)
  #
  def get(path, args = {}, &block)
    args = args || {}
    context  = args[:context]
    watch    = args[:watch] || false

    callback = args[:callback]
    callback = block if not block.nil?

    stat     = Zk::Stat.new

    if callback
      callback.extend Zk::AsyncCallback::DataCallback unless callback.is_a?(Proc) || callback.respond_to?(:processResult)
      getData(path, watch, callback, context)
    else
      [String.from_java_bytes(getData(path, watch, stat)), Stat.new(stat.to_a)]
    end
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end
  
  
  # Return the stat of the node of the given path. Return nil if no such a node exists.
  # 
  # If the watch is true and the call is successful (no exception is thrown), a watch will be left on the node with the given path. The watch will be triggered by 
  # a successful operation that creates/delete the node or sets the data on the node.
  #
  # Can be called with just the path, otherwise a hash with the arguments set.  Supports being executed asynchronousy by passing a callback object.
  # 
  # ==== Arguments
  # * <tt>path</tt> -- path of the node
  # * <tt>:watch</tt> -- defaults to false, set to true if you need to watch this node
  # * <tt>:callback</tt> -- provide a AsyncCallback::StatCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  # 
  # ==== Examples
  # ===== exists for path
  #   zk.exists("/path")
  #   # => ZooKeeper::Stat
  #
  # ===== exists for path with watch set
  #   zk.exists("/path", :watch => true)
  #   # => ZooKeeper::Stat
  #
  # ===== exists for non existent path
  #   zk.exists("/non_existent_path")
  #   # => nil
  #
  # ===== exist node asynchronously
  #
  #   class StatCallback
  #     def process_result(return_code, path, context, stat)
  #       # do processing here
  #     end
  #   end
  #  
  #   callback = StatCallback.new
  #   context = Object.new
  #
  #   zk.exists?("/path", :callback => callback, :context => context)
  def exists?(path, opts = {})
    opts = opts || {} #why do we have to do this?  I have no idea
    watch    = opts[:watch] || false
    callback = opts[:callback]
    context  = opts[:context]
    if callback
      callback.extend Zk::AsyncCallback::StatCallback unless callback.is_a?(Proc) || callback.respond_to?(:processResult)
      exists(path, watch, callback, context)
    else
      stat = exists(path, watch)
      return stat.nil? ? nil : Stat.new(stat.to_a)
    end
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end

  def close!
    close
  end

  # Set the data for the node of the given path if such a node exists and the given version matches the version of the node (if the given version is -1, it matches any 
  # node's versions). Return the stat of the node.
  # 
  # This operation, if successful, will trigger all the watches on the node of the given path left by get_data calls.
  # 
  # A KeeperException with error code KeeperException::NoNode will be thrown if no node with the given path exists. A KeeperException with error code 
  # KeeperException::BadVersion will be thrown if the given version does not match the node's version.  
  #
  # Called with a hash of arguments set.  Supports being executed asynchronousy by passing a callback object.
  # 
  # ==== Arguments
  # * <tt>:path</tt> -- path of the node
  # * <tt>:data</tt> -- data to set
  # * <tt>:version</tt> -- defaults to -1, otherwise set to the expected matching version
  # * <tt>:callback</tt> -- provide a AsyncCallback::StatCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  # 
  # ==== Examples
  #   zk.set("/path", "foo")
  #   zk.set("/path", "foo", :version => 0)
  #
  # ===== set data asynchronously
  #
  #   class StatCallback
  #     def process_result(return_code, path, context, stat)
  #       # do processing here
  #     end
  #   end
  #  
  #   callback = StatCallback.new
  #   context = Object.new
  #
  #   zk.set("/path", "foo", :callback => callback, :context => context)
  def set(path, data = "", args = {})
    version  = args[:version] || -1
    callback = args[:callback]
    context  = args[:context]
    
    if callback
      callback.extend Zk::AsyncCallback::StatCallback unless callback.is_a?(Proc) || callback.respond_to?(:processResult)
      setData(path, data.to_java_bytes, version, callback, context)
    else
      setData(path, data.to_java_bytes, version)
    end
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end

  # Delete the node with the given path. The call will succeed if such a node exists, and the given version matches the node's version (if the given version is -1, 
  # it matches any node's versions).
  # 
  # A KeeperException with error code KeeperException::NoNode will be thrown if the nodes does not exist.
  # 
  # A KeeperException with error code KeeperException::BadVersion will be thrown if the given version does not match the node's version.
  # 
  # A KeeperException with error code KeeperException::NotEmpty will be thrown if the node has children.
  # 
  # This operation, if successful, will trigger all the watches on the node of the given path left by exists API calls, and the watches on the parent node left by 
  # children API calls.
  #
  # Can be called with just the path, otherwise a hash with the arguments set.  Supports being executed asynchronousy by passing a callback object.
  # 
  # ==== Arguments
  # * <tt>path</tt> -- path of the node to be deleted
  # * <tt>:version</tt> -- defaults to -1, otherwise set to the expected matching version
  # * <tt>:callback</tt> -- provide a AsyncCallback::VoidCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  # 
  # ==== Examples
  #   zk.delete("/path")
  #   zk.delete("/path", :version => 0)
  #
  # ===== delete node asynchronously
  #
  #   class VoidCallback
  #     def process_result(return_code, path, context)
  #       # do processing here
  #     end
  #   end
  #  
  #   callback = VoidCallback.new
  #   context = Object.new
  #
  #   zk.delete(/path", :callback => callback, :context => context)
  def delete(path, args = {})
    version  = args[:version] || -1
    callback = args[:callback]
    context  = args[:context]
    
    if callback
      callback.extend Zk::AsyncCallback::VoidCallback unless callback.is_a?(Proc) || callback.respond_to?(:processResult)
      super(path, version, callback, context)
    else
      super(path, version)
    end
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end

  # Return the list of the children of the node of the given path.
  # 
  # If the watch is true and the call is successful (no exception is thrown), a watch will be left on the node with the given path. The watch willbe triggered by a
  # successful operation that deletes the node of the given path or creates/delete a child under the node.
  # 
  # A KeeperException with error code KeeperException::NoNode will be thrown if no node with the given path exists.
  # 
  # Can be called with just the path, otherwise a hash with the arguments set.  Supports being executed asynchronousy by passing a callback object.
  # 
  # ==== Arguments
  # * <tt>path</tt> -- path of the node
  # * <tt>:watch</tt> -- defaults to false, set to true if you need to watch this node
  # * <tt>:callback</tt> -- provide a AsyncCallback::ChildrenCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  # 
  # ==== Examples
  # ===== get children for path
  #   zk.create("/path", :data => "foo")
  #   zk.create("/path/child", :data => "child1", :sequence => true)
  #   zk.create("/path/child", :data => "child2", :sequence => true)
  #   zk.children("/path")
  #   # => ["child0", "child1"]
  #
  # ====== get children and set watch
  #   zk.children("/path", :watch => true)
  #   # => ["child0", "child1"]
  #
  # ===== get children asynchronously
  #
  #   class ChildrenCallback
  #     def process_result(return_code, path, context, children)
  #       # do processing here
  #     end
  #   end
  #  
  #   callback = ChildrenCallback.new
  #   context = Object.new
  #   zk.children("/path", :callback => callback, :context => context)
  def children(path, args = {})
    watch    = args[:watch] || false
    callback = args[:callback]
    context  = args[:context]

    if callback
      callback.extend Zk::AsyncCallback::ChildrenCallback unless callback.is_a?(Proc) || callback.respond_to?(:processResult)
      getChildren(path, watch, callback, context)
    else
      getChildren(path, watch).to_a
    end
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end
  
  # Return the ACL and stat of the node of the given path.
  # 
  # A KeeperException with error code KeeperException::Code::NoNode will be thrown if no node with the given path exists.  
  #
  # Can be called with just the path, otherwise a hash with the arguments set.  Supports being executed asynchronousy by passing a callback object.
  # 
  # ==== Arguments
  # * <tt>path</tt> -- path of the node
  # * <tt>:stat</tt> -- defaults to nil, provide a Stat object that will be set with the Stat information of the node path
  # * <tt>:callback</tt> -- provide a AsyncCallback::AclCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  # 
  # ==== Examples
  # ===== get acl
  #   zk.acls("/path")
  #   # => [ACL]
  #
  # ===== get acl with stat
  #   stat = ZooKeeper::Stat.new
  #   zk.acls("/path", :stat => stat)
  #
  # ===== get acl asynchronously
  #
  #   class AclCallback
  #     def processResult(return_code, path, context, acl, stat)
  #       # do processing here
  #     end
  #   end
  #  
  #   callback = AclCallback.new
  #   context = Object.new
  #   zk.acls("/path", :callback => callback, :context => context)
  def acls(path, args = {})
    callback = args[:callback]
    context  = args[:context]
    stat     = Zk::Stat.new

    if callback
      callback.extend Zk::AsyncCallback::AclCallback unless callback.is_a?(Proc) || callback.respond_to?(:processResult)
      getACL(path, stat, callback, context)
    else
      [getACL(path, stat).collect {|acl| acl.to_ruby}, Stat.new(stat.to_a)]
    end
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end
  
  # Add authentication information.
  #
  # ZooKeeper has the following built in schemes:
  # 
  # * world has a single id, anyone, that represents anyone.
  # * auth doesn't use any id, represents any authenticated user.
  # * digest uses a _username:password_ string to generate MD5 hash which is then used as an ACL ID identity. Authentication is done by sending the _username:password_ in clear text. When used in the ACL the expression will be the _username:base64_encoded_SHA1_password_digest_.
  # * host uses the client host name as an ACL ID identity. The ACL expression is a hostname suffix. For example, the ACL expression _host:corp.com_ matches the ids _host:host1.corp.com_ and _host:host2.corp.com_, but not _host:host1.store.com_.
  # * ip uses the client host IP as an ACL ID identity. The ACL expression is of the form _addr/bits_ where the most significant _bits_ of _addr_ are matched against the most significant _bits_ of the client host IP.
  #
  # Called with a hash of arguments set
  # 
  # ==== Arguments
  # * <tt>:scheme</tt> -- scheme
  # * <tt>:auth</tt> -- authentication
  # 
  # ==== Examples
  #   zk.add_auth_info(:scheme => "digest", :auth => "ben:password")
  def add_auth_info(auth, args = {})
    scheme = args[:scheme] || "digest"
    super(scheme, auth.to_java_bytes)
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end

  # Set the ACL for the node of the given path if such a node exists and the given version matches the version of the node. Return the stat of the node.
  # 
  # A KeeperException with error code KeeperException::Code::NoNode will be thrown if no node with the given path exists.
  # 
  # A KeeperException with error code KeeperException::Code::BadVersion will be thrown if the given version does not match the node's version.
  #
  # Called with a hash of arguments set.  Supports being executed asynchronousy by passing a callback object.
  # 
  # ==== Arguments
  # * <tt>path</tt> -- path of the node
  # * <tt>:acl</tt> -- acl to set
  # * <tt>:version</tt> -- defaults to -1, otherwise set to the expected matching version
  # * <tt>:callback</tt> -- provide a AsyncCallback::StatCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  # 
  # ==== Examples
  # TBA - waiting on clarification of method use
  def set_acl(path, args = {})
    acls     = args[:acl]
    version  = args[:version] || -1
    callback = args[:callback]
    context  = args[:context]

    if callback
      callback.extend AsyncCallback::StatCallback unless callback.is_a?(Proc) || callback.respond_to?(:processResult)
      super(path, acls.collect{|acl| Zk::ACL.to_java(acl)}, version, callback, context)
    else
      super(path, acls.collect{|acl| Zk::ACL.to_java(acl)}, version)
    end
  rescue Exception => e
    raise_keeper_exception(e, caller)
  end

private
  def raise_keeper_exception(e, orig_caller)
    if e.respond_to?(:code) and KeeperException.recognized_code?(e.code)
      raise KeeperException.by_code(e.code), nil, orig_caller
    else
      raise e
    end
  end

end
