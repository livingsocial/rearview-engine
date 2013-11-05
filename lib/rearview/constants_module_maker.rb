module Rearview
  module ConstantsModuleMaker

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def make_constants_module(*args)
        mod_name = args[0]
        mod_opts = args[1]
        m = Module.new
        constant_values = []
        if(mod_opts[:constants].kind_of?(Array))
          mod_opts[:constants].each { |c|
            key = c.to_s.upcase
            value = if( mod_opts[:upcase_values] )
                      c.to_s.upcase
                    elsif( mod_opts[:camelize_value] )
                      c.to_s.camelize
                    else
                      c.to_s
                    end
            m.const_set(key,value)
            constant_values.push(value)
          }
        else
          mod_opts[:constants].each { |k,v|
            m.const_set(k.to_s.upcase,v)
            constant_values.push(v)
          }
        end
        m.const_set("ALL_VALUES__",constant_values)
        m.instance_eval {
          def values
            const_get("ALL_VALUES__")
          end
        }
        i18n_format = nil
        if(!mod_opts[:i18n_format])
          i18n_format = "models.#{self.name.underscore}.#{mod_name}.%s"
        else
          i18n_format = mod_opts[:i18n_format]
        end
        if(i18n_format)
          m.instance_eval %Q{
            def t(c)
               name = ( c.kind_of?(Symbol) ? const_get(c) : c)
               I18n.t sprintf(\"#{i18n_format}\",name)
            end
          }
        end
        self.const_set(mod_name.to_s.camelize,m)
        m
      end
    end

  end
end
