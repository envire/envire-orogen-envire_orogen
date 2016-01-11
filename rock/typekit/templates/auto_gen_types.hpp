/* Generated from orogen/lib/orogen/templates/typekit/marshalling_types.hpp */

<% target_namespace = Typelib.namespace(intermediate_type)
   target_basename  = Typelib.basename(intermediate_type)
   target_basename.gsub!('/', '::')
%>

#ifndef _OROGEN_WRAPPER_TYPES_<%= target_basename.upcase %>_HPP
#define _OROGEN_WRAPPER_TYPES_<%= target_basename.upcase %>_HPP

#include <vector>
#include <stdint.h>

<%= Generation.adapt_namespace('/', target_namespace) %>

struct <%= target_basename %>
{
    std::vector<uint8_t> binary;
};

<%= Generation.adapt_namespace(target_namespace, '/') %>

#endif
