<%
# Generate boost serialization convertions
%>
void orogen_typekits::toIntermediate(<%= Typelib::Type.normalize_cxxname(intermediate_type) %>& intermediate, <%= Typelib::Type.normalize_cxxname(type) %> const& real_type)
{
    intermediate.binary.reserve(1000000);
    BinaryOutputBuffer buffer(&intermediate.binary);
    std::ostream ostream(&buffer);
    boost::archive::binary_oarchive oa(ostream);

    oa << real_type;
}

void orogen_typekits::fromIntermediate(<%= Typelib::Type.normalize_cxxname(type) %>& real_type, <%= Typelib::Type.normalize_cxxname(intermediate_type) %> const& intermediate)
{
    BinaryInputBuffer buffer(intermediate.binary);
    std::istream istream(&buffer);
    boost::archive::binary_iarchive ia(istream);

    ia >> real_type;
}
