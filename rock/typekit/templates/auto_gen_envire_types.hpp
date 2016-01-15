/* Generated from orogen/lib/orogen/templates/typekit/marshalling_types.hpp */

<% target_namespace = Typelib.namespace(intermediate_type)
   target_basename  = Typelib.basename(intermediate_type)
   target_basename.gsub!('/', '::')
%>

#ifndef _OROGEN_WRAPPER_TYPES_<%= target_basename.upcase %>_HPP
#define _OROGEN_WRAPPER_TYPES_<%= target_basename.upcase %>_HPP

#include <vector>
#include <string>
#include <stdint.h>
#include <base/Time.hpp>

<%= Generation.adapt_namespace('/', target_namespace) %>

struct <%= target_basename %>
{
    base::Time time;
    std::string frame;
    std::vector<uint8_t> map_data;
};

<%= Generation.adapt_namespace(target_namespace, '/') %>

#endif
