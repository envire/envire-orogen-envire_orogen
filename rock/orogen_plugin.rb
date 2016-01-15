
class OroGen::Gen::RTT_CPP::Typekit

    def wrapper_type_name_for type
        type = type.to_str
        type = Typelib::Type.normalize_typename(type)
        path = Typelib.split_typename(type)
        path.map! do |p|
            p.gsub(/[<>\[\], \/]/, '_')
        end
        "/" + path.join("/") + "_w"
    end

    def extend_includes_by_boost_serialization_includes options
        if options[:includes].respond_to?(:to_str)
            options[:includes] = [options[:includes]]
        end
        options[:includes].push("boost/archive/polymorphic_binary_iarchive.hpp")
        options[:includes].push("boost/archive/polymorphic_binary_oarchive.hpp")
        options[:includes].push("envire_core/typekit/BinaryBufferHelper.hpp")
        options
    end

    def opaque_autogen type, options = Hash.new
        options = Kernel.validate_options options,
            :include => [],
            :includes => [],
            :type => :boost_serialization

        # Check if type is already available
        begin
            t = find_type(type)
            if !t.nil?
                raise ArgumentError, "Type #{type} is already defined."
            end
        rescue Typelib::NotFound
        end

        orogen_install_path = File.expand_path(File.join('..'), File.dirname(__FILE__))

        if options[:type] == :boost_serialization
            options.delete(:type)
            options[:needs_copy] = true

            # extend includes
            options = extend_includes_by_boost_serialization_includes options

            intermediate_type = wrapper_type_name_for type

            # create and load intermediate wrapper type
            begin
                t = find_type(intermediate_type)
            rescue Typelib::NotFound
                auto_gen_wrapper_code = Generation.render_template orogen_install_path, 'templates', 'auto_gen_types.hpp', binding
                path = Generation.save_automatic 'typekit', 'types', self.name, "wrappers", "#{Typelib.basename(intermediate_type)}.hpp", auto_gen_wrapper_code
                self.load(path, false)
            end

            # create c++ convertion code from template
            auto_gen_wrapper_code = Generation.render_template orogen_install_path, 'templates', 'opaque_convertions_boost_serialization.cpp', binding

            # register opaque type
            opaque_type(type, intermediate_type, options) {auto_gen_wrapper_code}

        elsif options[:type] == :envire_serialization
            options.delete(:type)
            options[:needs_copy] = true

            # extend includes
            options = extend_includes_by_boost_serialization_includes options

            intermediate_type = wrapper_type_name_for type

            # create and load intermediate wrapper type
            begin
                t = find_type(intermediate_type)
            rescue Typelib::NotFound
                auto_gen_wrapper_code = Generation.render_template orogen_install_path, 'templates', 'auto_gen_envire_types.hpp', binding
                path = Generation.save_automatic 'typekit', 'types', self.name, "wrappers", "#{Typelib.basename(intermediate_type)}.hpp", auto_gen_wrapper_code
                self.load(path, false)
            end

            # create c++ convertion code from template
            auto_gen_wrapper_code = Generation.render_template orogen_install_path, 'templates', 'opaque_convertions_envire_serialization.cpp', binding

            # register opaque type
            opaque_type(type, intermediate_type, options) {auto_gen_wrapper_code}

        else
            raise ArgumentError, "Cannot generate opaque, #{options[:type]} is an unknown serialization type!"
        end

    end

end
