<%
# Generate boost serialization convertions
%>

void orogen_typekits::toIntermediate(<%= Typelib::Type.normalize_cxxname(intermediate_type) %>& intermediate, <%= Typelib::Type.normalize_cxxname(type) %> const& real_type)
{
    /**
     * @brief Helper class which defines a std::streambuf which writes
     * direcly in a std::vector<uint8_t>.
     */
    class BinaryOutputBuffer : public std::streambuf
    {
    public:
        BinaryOutputBuffer(std::vector<uint8_t> *buffer) : buffer(buffer)
        {
            this->setp((char*)buffer->data(), (char*)(buffer->data() + buffer->size()));
        }

        /**
         * This method is called by sputc if the current put pointer is equal to the end pointer.
         */
        int overflow(int c)
        {
            // increase buffer size by one
            buffer->resize(buffer->size()+1);
            // reset offsets
            this->setp((char*)(buffer->data() + buffer->size()-1), (char*)(buffer->data() + buffer->size()));
            // recall sputc
            return this->sputc(c);
        }

    private:
        std::vector<uint8_t> *buffer;
    };

    intermediate.binary.reserve(1000000);
    BinaryOutputBuffer buffer(&intermediate.binary);
    std::ostream ostream(&buffer);
    boost::archive::binary_oarchive oa(ostream);

    oa << real_type;
}

void orogen_typekits::fromIntermediate(<%= Typelib::Type.normalize_cxxname(type) %>& real_type, <%= Typelib::Type.normalize_cxxname(intermediate_type) %> const& intermediate)
{
    /**
     * @brief Helper class which defines a std::streambuf which reads
     * direcly out of a std::vector<uint8_t>.
     */
    class BinaryInputBuffer : public std::streambuf
    {
    public:
        BinaryInputBuffer(const std::vector<uint8_t>& buffer) : BinaryInputBuffer(buffer.data(), buffer.size()) {}
        BinaryInputBuffer(const uint8_t* data, size_t size) : BinaryInputBuffer(data, data + size) {}
        BinaryInputBuffer(const uint8_t* begin, const uint8_t* end)
        {
            this->setg((char*)begin, (char*)begin, (char*)end);
        }
    };

    BinaryInputBuffer buffer(intermediate.binary);
    std::istream istream(&buffer);
    boost::archive::binary_iarchive ia(istream);

    ia >> real_type;
}
