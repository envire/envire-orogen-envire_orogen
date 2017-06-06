
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

    # Returns the SpatioTemporal typename for a given embedded type.
    #
    # @param [string] embedded typename
    def spatio_temporal_typename_for embedded_typename
        "/envire/core/SpatioTemporal<#{embedded_typename}>"
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
        options[:includes].push("envire_orogen/typekit/BinaryBufferHelper.hpp")
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
    # +:envire_serialization+ the opaque type must inherit from envire::core::ItemBase and the
    #                           :embedded_type option must be set. The :embedded_type can be a known
    #                           typelib type, an opaque type or a generated opaque type on its own.
    #                           @deprecated use spatio_temporal instead
    #
    # Examples:
    #    opaque_autogen '/gridmaps/Grid2D',
    #                   :includes => "gridmaps/Grid2D.hpp",
    #                   :type => :boost_serialization
    #
    #    opaque_autogen '/envire/pcl/PointCloud',
    #                   :includes => "envire_pcl/PointCloud.hpp",
    #                   :type => :envire_serialization,
    #                   :embedded_type => "/pcl/PCLPointCloud2"
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

        elsif options[:type] == :envire_serialization
            OroGen::Gen::RTT_CPP.info "Note that using opaque_autogen with the :envire_serialization option is deprecated. Use spatio_temporal [embedded_type] instead."

            # check if embedded type is set
            if not options[:embedded_type].respond_to?(:to_str) or options[:embedded_type].empty?
                raise ArgumentError, "Cannot generate opaque for type #{type} without a valid type name for the embedded type of the envire::core::Item. (E.g. :embedded_type => '/pcl/PCLPointCloud2')"
            end

            begin
                # try to find embedded type
                embedded_type = find_type options[:embedded_type]
            rescue Typelib::NotFound
                OroGen::Gen::RTT_CPP.info "Couldn't find typelib type for embedded type #{options[:embedded_type]}, trying to generate boost serialization based opaque type."
                # generate boost serialization based opaque type if not available
                opaque_autogen options[:embedded_type], :includes => options[:includes], :include => options[:include], :type => :boost_serialization
                embedded_type = find_type options[:embedded_type]
            end

            # extend includes
            options = extend_includes_by_boost_serialization_includes options

            intermediate_type = wrapper_type_name_for type

            #create and load intermediate wrapper type
            begin
                t = find_type(intermediate_type)
            rescue Typelib::NotFound
                auto_gen_wrapper_code = Generation.render_template orogen_install_path, 'templates', 'auto_gen_envire_types.hpp', binding
                path = Generation.save_automatic 'typekit', 'types', self.name, "wrappers", "envire_serialization", "#{Typelib.basename(intermediate_type)}.hpp", auto_gen_wrapper_code
                self.load(path, false)
            end

            # create c++ convertion code from template
            opaque_convertion_code = Generation.render_template orogen_install_path, 'templates', 'opaque_convertions_envire_serialization.cpp', binding

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

    # Generates a SpatioTemporal<embedded_typename> type of the given embedded type.
    #
    # If the embedded type has an opaque type, it will create a SpatioTemporal type
    # using it's opaque and creates a conversion. Note that the embedded type needs
    # to be already exported.
    #
    # The following option is available:
    # +:include+ can be used to include additional headers.
    #
    # Examples:
    #    point_cloud_st = spatio_temporal '/pcl/PCLPointCloud2'
    #    export_types point_cloud_st
    #
    # @param [string] embedded typename
    def spatio_temporal embedded_typename, options = Hash.new
        # create a validated options-hash
        options = Kernel.validate_options options,
            # just the plain name of the header like "path/Header.hpp"
            :include => []

        orogen_install_path = File.expand_path(File.join('..'), File.dirname(__FILE__))

        # check if embedded type is set
        if not embedded_typename.respond_to?(:to_str) or embedded_typename.empty?
            raise ArgumentError, "Cannot generate #{spatio_temporal_typename_for "T"} type without a valid type name for the embedded type (E.g. '/pcl/PCLPointCloud2')"
        end

        begin
            # try to find the embedded type
            embedded_type = find_type embedded_typename
        rescue Typelib::NotFound
            raise ArgumentError, "Couldn't find typelib type for embedded type #{embedded_typename}, please export the type first!"
        end

        type_name = spatio_temporal_typename_for embedded_type.name

        # check if type is already available
        begin
            t = find_type(type_name)
            if !t.nil?
               return t
            end
        rescue Typelib::NotFound
        end

        auto_gen_wrapper_code = Generation.render_template orogen_install_path, 'templates', 'auto_gen_spatio_temporal_types.hpp', binding
        file_name = Typelib.basename(embedded_type.name).gsub(/[<>\[\], \/]/, '_')
        path = Generation.save_automatic 'typekit', 'types', self.name, "wrappers", "spatio_temporal", "#{file_name}.hpp", auto_gen_wrapper_code
        self.load(path)

        if embedded_type.opaque?
            if options[:include].respond_to?(:to_str)
                options[:include] = [options[:include]]
            end
            options[:include].concat(include_for_type(embedded_type))
            options[:include].push("envire_core/items/SpatioTemporal.hpp")
            embedded_type_intermediate = intermediate_type_for embedded_type

            intermediate_type = spatio_temporal_typename_for embedded_type_intermediate.name

            # create c++ convertion code from template
            opaque_convertion_code = Generation.render_template orogen_install_path, 'templates', 'opaque_convertions_spatio_temporal.cpp', binding
            opaque_type(type_name, intermediate_type, options) {opaque_convertion_code}
        end

        # perform pending loads
        if has_pending_loads?
            perform_pending_loads
        end

        # add aliases
        aliases = registry.aliases_of embedded_type
        aliases.each do |a|
            registry.alias spatio_temporal_typename_for(a), type_name
        end


        find_type(type_name)
    end

end

class OroGen::Spec::TaskContext

    # Resolves the spatio temporal type of a given embedded type
    # or creates one if it can't be found.
    #
    # Example:
    #   output_port "pointcloud", spatio_temporal("/pcl/PCLPointCloud2")
    #
    def spatio_temporal(name)
        base_type = project.resolve_type(name)
        full_name = "/envire/core/SpatioTemporal<#{base_type.name}>"
        begin
            project.resolve_type(full_name)
        rescue Typelib::NotFound
            if project.typekit(true).respond_to?(:spatio_temporal)
                project.typekit(true).spatio_temporal(name)
                project.resolve_type(full_name)
            else raise
            end
        end
    end

end