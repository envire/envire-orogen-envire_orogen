<%
# Generate boost serialization convertions
%>
void orogen_typekits::toIntermediate(<%= Typelib::Type.normalize_cxxname(intermediate_type) %>& intermediate, <%= Typelib::Type.normalize_cxxname(type) %> const& real_type)
{
    intermediate.time = real_type.getTime();
    intermediate.frame = real_type.getFrame();
    intermediate.map_data.reserve(1000000);
    BinaryOutputBuffer buffer(&intermediate.map_data);
    std::ostream ostream(&buffer);
    boost::archive::polymorphic_binary_oarchive oa(ostream);

    oa << real_type;
}

void orogen_typekits::fromIntermediate(<%= Typelib::Type.normalize_cxxname(type) %>& real_type, <%= Typelib::Type.normalize_cxxname(intermediate_type) %> const& intermediate)
{
    BinaryInputBuffer buffer(intermediate.map_data);
    std::istream istream(&buffer);
    boost::archive::polymorphic_binary_iarchive ia(istream);

    ia >> real_type;
    real_type.setTime(intermediate.time);
    real_type.setFrame(intermediate.frame);
}
