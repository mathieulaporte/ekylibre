module CleanSupport

  class << self

    def rec(hash, *keys)
      key = keys.shift
      if hash.is_a?(Hash)
        return rec(hash[key], *keys) if keys.any?
        return hash[key]
      end
      return nil
    end

    def hash_to_yaml(hash, depth=0)
      code = "\n"
      x = hash.to_a.sort{|a,b| a[0].to_s.gsub("_"," ").strip<=>b[0].to_s.gsub("_"," ").strip}
      x.each_index do |i|
        k, v = x[i][0], x[i][1]
        code += "  "*depth+k.to_s+":"+(v.is_a?(Hash) ? hash_to_yaml(v, depth+1) : " "+yaml_value(v))+(i == x.size-1 ? '' : "\n") if v
      end
      code
    end

    def yaml_to_hash(filename)
      hash = YAML::load(IO.read(filename).gsub(/^(\s*)no:(.*)$/, '\1__no_is_not__false__:\2'))
      return deep_symbolize_keys(hash)
    end

    def hash_sort_and_count(hash, depth=0)
      hash ||= {}
      code, count = "", 0
      for key, value in hash.sort{|a, b| a[0].to_s <=> b[0].to_s}
        if value.is_a? Hash
          scode, scount = hash_sort_and_count(value, depth+1)
          code += "  "*depth+key.to_s+":\n"+scode
          count += scount
        else
          code += "  "*depth+key.to_s+": "+yaml_value(value, depth+1)+"\n"
          count += 1
        end
      end
      return code, count
    end


    def hash_count(hash)
      count = 0
      for key, value in hash
        count += (value.is_a?(Hash) ? hash_count(value) : 1)
      end
      return count
    end

    def sort_yaml_file(filename, log=nil)
      yaml_file = Rails.root.join("config", "locales", ::I18n.locale.to_s, "#{filename}.yml")
      # translation = hash_to_yaml(yaml_to_hash(file)).strip
      translation, total = hash_sort_and_count(yaml_to_hash(yaml_file))
      File.open(yaml_file, "wb") do |file|
        file.write translation.strip
      end
      count = 0
      log.write "  - #{(filename.to_s+'.yml:').ljust(20)} #{(100*(total-count)/total).round.to_s.rjust(3)}% (#{total-count}/#{total})\n" if log
      return total
    end

    def deep_symbolize_keys(hash)
      hash.inject({}) { |result, (key, value)|
        value = deep_symbolize_keys(value) if value.is_a? Hash
        key = :no if key.to_s == "__no_is_not__false__"
        result[(key.to_sym rescue key) || key] = value
        result
      }
    end


    def yaml_value(value, depth=0)
      if value.is_a?(Array)
        "["+value.collect{|x| yaml_value(x)}.join(", ")+"]"
      elsif value.is_a?(Symbol)
        ":"+value.to_s
      elsif value.is_a?(Hash)
        hash_to_yaml(value, depth+1)
      elsif value.is_a?(Numeric)
        value.to_s
      else
        # "'"+value.to_s.gsub("'", "''")+"'"
        '"'+value.to_s.gsub("\u00A0", "\\_")+'"'
      end
    end

    def hash_diff(hash, ref, depth=0, mode = nil)
      hash ||= {}
      ref ||= {}
      keys = (ref.keys+hash.keys).uniq.sort{|a,b| a.to_s.gsub("_"," ").strip<=>b.to_s.gsub("_"," ").strip}
      code, count, total = "", 0, 0
      for key in keys
        h, r = hash[key], ref[key]
        # total += 1 unless r.is_a? Hash
        if r.is_a?(Hash) and (h.is_a?(Hash) or h.nil?)
          scode, scount, stotal = hash_diff(h, r, depth+1, mode)
          code  << "  "*depth+key.to_s+":\n"+scode
          count += scount
          total += stotal
        elsif r and h.nil?
          code  << "  "*depth+"# "+key.to_s+": "+ (mode == :humanize ? key.to_s.humanize : yaml_value(r, depth+1))+"\n"
          count += 1
          total += 1
        elsif r and h and r.class == h.class
          code  << "  "*depth+key.to_s+": "+yaml_value(h, depth+1)+"\n"
          total += 1
        elsif r and h and r.class != h.class
          code  << "  "*depth+key.to_s+": "+(yaml_value(h, depth)+"\n").gsub(/\n/, " #? #{r.class.name} excepted (#{h.class.name+':'+h.inspect})\n")
          total += 1
        elsif h and r.nil?
          code  << "  "*depth+key.to_s+": "+(yaml_value(h, depth)+"\n").to_s.gsub(/\n/, " #?\n")
        elsif r.nil?
          code  << "  "*depth+key.to_s+": #?\n"
        end
      end
      return code, count, total
    end

    # Lists all actions of all controller by loading them and list action_methods
    def actions_hash
      controllers = controllers_in_file
      ref = HashWithIndifferentAccess.new
      for controller in controllers_in_file
        ref[controller.controller_path] = controller.action_methods.to_a.sort
      end
      return ref
    end

    # Lists all models that inherits of ActiveRecord but are not system
    def models_in_file
      Dir.glob(Rails.root.join("app", "models", "*.rb")).each { |file| require file }
      return ObjectSpace
        .each_object(Class)
        .select { |klass| klass < ActiveRecord::Base }
        .select{ |x| not x.name.match(/\AActiveRecord\:\:/) and not x.abstract_class? }
        .uniq
        .sort{|a,b| a.name <=> b.name}
    end

    # Lists all controller that inherits of ApplicationController included
    def controllers_in_file
      Dir.glob(Rails.root.join("app", "controllers", "**", "*.rb")).each { |file| require file }
      return ObjectSpace
        .each_object(Class)
        .select { |klass| klass <= ApplicationController }
        .sort{|a,b| a.name <=> b.name}
    end

    # Lists helpers paths
    def helpers_in_file
      dir = Rails.root.join("app", "helpers")
      list = Dir.glob(dir.join("**", "*.rb")).collect do |h|
        Pathname.new(h).relative_path_from(dir).to_s[0..-4]
      end
      return list
    end

  end

end
