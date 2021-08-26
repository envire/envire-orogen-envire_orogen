
class OroGen::Gen::RTT_CPP::Typekit

    # Generates a wrapper typename for the given typename.
    #
    # It will exchance special characters with an '_' and add '_w' to
    # the typename.
    #
    # @param [string] typename
    def wrapper_type_name_for type
        type = type.to_str
        type = Typelib::Type.normalize_typename(type)
        path = Typelib.split_typename(type)
        path.map! do |p|
            p.gsub(/[<>\[\], \/]/, '_').gsub(/\*/, 'P')
        end
        "/" + path.join("/") + "_w"
    end

    # Adds boost serialization related includes to a given hash of options.
    #
    # It will extend options[:includes], which can be an array or a string.
    #
    # @param [Hash] options
    def extend_includes_by_boost_serialization_includes options
        if options[:includes].respond_to?(:to_str)
            options[:includes] = [options[:includes]]
        end
        options[:includes].push("boost/archive/binary_iarchive.hpp")
        options[:includes].push("boost/archive/binary_oarchive.hpp")
        options
    end

    # Generates an opaque conversion for the given type.
    #
    # It registers a wrapper type based on the selected serialization method
    # and generates the conversion between the opaque type and its wrapper type.
    #
    # The following options are available:
    # +:include+ and +:includes+ are used to include the headers of the opaque type.
    # +:type+ selects the serialization type, default is +:boost_serialization+
    #
    # Serialization types:
    # +:boost_serialization+ the opaque type must support boost serialization. It is used to
    #                           store the internal data of the opaque in binary form.
    #
    # Examples:
    #    opaque_autogen '/gridmaps/Grid2D',
    #                   :includes => "gridmaps/Grid2D.hpp",
    #                   :type => :boost_serialization
    #
    #
    # @param [string] opaque typename
    def opaque_autogen type, options = Hash.new
        options = Kernel.validate_options options,
            :include => [],
            :includes => [],
            :type => :boost_serialization,
            :alias_name => "",
            :embedded_type => ""

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

            # extend includes
            options = extend_includes_by_boost_serialization_includes options

            intermediate_type = wrapper_type_name_for type

            # create and load intermediate wrapper type
            begin
                t = find_type(intermediate_type)
            rescue Typelib::NotFound
                auto_gen_wrapper_code = Generation.render_template orogen_install_path, 'templates', 'auto_gen_types.hpp', binding
                path = Generation.save_automatic 'typekit', 'types', self.name, "wrappers", "boost_serialization", "#{Typelib.basename(intermediate_type)}.hpp", auto_gen_wrapper_code
                self.load(path, false)
            end

            # create c++ convertion code from template
            opaque_convertion_code = Generation.render_template orogen_install_path, 'templates', 'opaque_convertions_boost_serialization.cpp', binding

            # register opaque type
            opaque_type(type, intermediate_type, :includes => options[:includes], :needs_copy => true) {opaque_convertion_code}
        else
            raise ArgumentError, "Cannot generate opaque, #{options[:type]} is an unknown serialization type!"
        end

        # add alias name for type
        if not options[:alias_name].nil? and not options[:alias_name].empty?
            options[:alias_name].gsub!('::', '/')
            if options[:alias_name].chr != '/'
                options[:alias_name].insert(0, '/')
            end
            registry.alias options[:alias_name], type
        end
    end

end

