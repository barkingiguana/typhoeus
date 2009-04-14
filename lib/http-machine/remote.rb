module HTTPMachine
  USER_AGENT = "HTTPMachine - http://github.com/pauldix/http-machine/tree/master"
  
  def self.included(base)
    base.extend ClassMethods
  end
    
  module ClassMethods
    def get(url, options = {}, &block)
      if HTTPMachine.multi_running?
        HTTPMachine.add_easy_request(base_easy_object(url, :get, options, filter_wrapper_block(:get, block)))
      else
        HTTPMachine.service_access do
          get(url, options, &block)
        end
      end
    end
    
    def post(url, options = {}, &block)
      if HTTPMachine.multi_running?
        HTTPMachine.add_easy_request(base_easy_object(url, :post, options, filter_wrapper_block(:post, block)))
      else
        HTTPMachine.service_access do
          post(url, options, &block)
        end
      end
    end

    def put(url, options = {}, &block)
      if HTTPMachine.multi_running?
        HTTPMachine.add_easy_request(base_easy_object(url, :put, options, filter_wrapper_block(:put, block)))
      else
        HTTPMachine.service_access do
          put(url, options, &block)
        end
      end      
    end
    
    def delete(url, options = {}, &block)
      if HTTPMachine.multi_running?
        HTTPMachine.add_easy_request(base_easy_object(url, :delete, options, filter_wrapper_block(:delete, block)))
      else
        HTTPMachine.service_access do
          delete(url, options, &block)
        end
      end
    end
    
    def base_easy_object(url, method, options, block)
      easy = HTTPMachine::Easy.new
      
      easy.url                   = url
      easy.method                = method
      easy.headers["User-Agent"] = (options[:user_agent] || HTTPMachine::USER_AGENT)
      easy.params                = options[:params] if options[:params]
      easy.request_body          = options[:body] if options[:body]
      easy.on_success            = block
      easy.on_failure            = block
      
      easy
    end
    
    def filter_wrapper_block(method_name, block)
      after_filters = @after_filters || []
      wrapper = lambda do |easy_object|
        after_filters.each do |filter|
          send(filter.method_name, easy_object) if filter.apply_filter?(method_name)
        end
        block.call(easy_object)
      end
    end
    
    def base_uri(base_uri)
      @base_uri = base_uri
    end
    
    def after_filter(method_name, options = {})
      @after_filters ||= []
      @after_filters << Filter.new(method_name, options)
    end
    
    def call_remote_method(method_name, options, block)
      m = @remote_methods[method_name]
      if m.http_method == :get
        get("", options.merge(m.options), &block)
      end
    end
    
    def remote_method(name, args = {})
      @remote_methods ||= {}
      @remote_methods[name] = RemoteMethod.new(:get, args)
      class_eval <<-SRC
        def self.#{name.to_s}(options = {}, &block)
          call_remote_method(:#{name.to_s}, options, block)
        end
      SRC
    end
  end # ClassMethods
end