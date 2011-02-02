module ZooKeeper
  # this isn't really used in this gem
  # @private
  # :nodoc:
  class ACL
    attr_reader :permissions, :id
    
    def initialize(permissions, id)
      @permissions, @id = permissions, id
    end
    
    def ==(obj)
      self.permissions == obj.permissions &&
      self.id == obj.id
    end

   OPEN_ACL_UNSAFE = [ACL.new(Permission::ALL,  Id::ANYONE_ID_UNSAFE)]    
   READ_ACL_UNSAFE = [ACL.new(Permission::READ, Id::ANYONE_ID_UNSAFE)]    
   CREATOR_ALL_ACL = [ACL.new(Permission::ALL | Permission::ADMIN, Id::AUTH_IDS)]    

  end
end
