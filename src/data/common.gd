#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION = 3

const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
		
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var is_map_field : bool = false
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && varint[8] == 0xFF:
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_double()
		else:
			for i in range(index + count - 1, index - 1, -1):
				value |= (bytes[i] & 0xFF)
				if i != index:
					value <<= 8
		return value

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var result : PackedByteArray = PackedByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								val_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


enum MESSAGE_ID {
	UNKNOWN_MSG = 0,
	DUMB_REQUEST = 1,
	INV_UNIT_INFO = 100,
	INV_CONTAINER_REQ = 101,
	INV_CONTAINER_RSP = 102
}

class DUMB_REQUEST:
	func _init():
		var service
		
		_req_msg = PBField.new("req_msg", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 0, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = _req_msg
		data[_req_msg.tag] = service
		
	var data = {}
	
	var _req_msg: PBField
	func get_req_msg():
		return _req_msg.value
	func clear_req_msg() -> void:
		data[0].state = PB_SERVICE_STATE.UNFILLED
		_req_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_req_msg(value) -> void:
		_req_msg.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Header:
	func _init():
		var service
		
		_msg_id = PBField.new("msg_id", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 0, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = _msg_id
		data[_msg_id.tag] = service
		
		_bus_mask = PBField.new("bus_mask", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _bus_mask
		data[_bus_mask.tag] = service
		
		_timestamp = PBField.new("timestamp", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _timestamp
		data[_timestamp.tag] = service
		
	var data = {}
	
	var _msg_id: PBField
	func get_msg_id():
		return _msg_id.value
	func clear_msg_id() -> void:
		data[0].state = PB_SERVICE_STATE.UNFILLED
		_msg_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_msg_id(value) -> void:
		_msg_id.value = value
	
	var _bus_mask: PBField
	func get_bus_mask() -> int:
		return _bus_mask.value
	func clear_bus_mask() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_bus_mask.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_bus_mask(value : int) -> void:
		_bus_mask.value = value
	
	var _timestamp: PBField
	func get_timestamp() -> float:
		return _timestamp.value
	func clear_timestamp() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_timestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_timestamp(value : float) -> void:
		_timestamp.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GameMessage:
	func _init():
		var service
		
		_header = PBField.new("header", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 0, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _header
		service.func_ref = Callable(self, "new_header")
		data[_header.tag] = service
		
		_dumb_req_msg = PBField.new("dumb_req_msg", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _dumb_req_msg
		service.func_ref = Callable(self, "new_dumb_req_msg")
		data[_dumb_req_msg.tag] = service
		
		_inv_unit_info_msg = PBField.new("inv_unit_info_msg", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 100, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _inv_unit_info_msg
		service.func_ref = Callable(self, "new_inv_unit_info_msg")
		data[_inv_unit_info_msg.tag] = service
		
		_inv_container_req_msg = PBField.new("inv_container_req_msg", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 101, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _inv_container_req_msg
		data[_inv_container_req_msg.tag] = service
		
		_inv_container_rsp_msg = PBField.new("inv_container_rsp_msg", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 102, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _inv_container_rsp_msg
		service.func_ref = Callable(self, "new_inv_container_rsp_msg")
		data[_inv_container_rsp_msg.tag] = service
		
	var data = {}
	
	var _header: PBField
	func get_header() -> Header:
		return _header.value
	func clear_header() -> void:
		data[0].state = PB_SERVICE_STATE.UNFILLED
		_header.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_header() -> Header:
		_header.value = Header.new()
		return _header.value
	
	var _dumb_req_msg: PBField
	func has_dumb_req_msg() -> bool:
		return data[1].state == PB_SERVICE_STATE.FILLED
	func get_dumb_req_msg() -> DUMB_REQUEST:
		return _dumb_req_msg.value
	func clear_dumb_req_msg() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_dumb_req_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_dumb_req_msg() -> DUMB_REQUEST:
		data[1].state = PB_SERVICE_STATE.FILLED
		_inv_unit_info_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[100].state = PB_SERVICE_STATE.UNFILLED
		_inv_container_req_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
		data[101].state = PB_SERVICE_STATE.UNFILLED
		_inv_container_rsp_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[102].state = PB_SERVICE_STATE.UNFILLED
		_dumb_req_msg.value = DUMB_REQUEST.new()
		return _dumb_req_msg.value
	
	var _inv_unit_info_msg: PBField
	func has_inv_unit_info_msg() -> bool:
		return data[100].state == PB_SERVICE_STATE.FILLED
	func get_inv_unit_info_msg() -> InvUnitInfo:
		return _inv_unit_info_msg.value
	func clear_inv_unit_info_msg() -> void:
		data[100].state = PB_SERVICE_STATE.UNFILLED
		_inv_unit_info_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_inv_unit_info_msg() -> InvUnitInfo:
		_dumb_req_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		data[100].state = PB_SERVICE_STATE.FILLED
		_inv_container_req_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
		data[101].state = PB_SERVICE_STATE.UNFILLED
		_inv_container_rsp_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[102].state = PB_SERVICE_STATE.UNFILLED
		_inv_unit_info_msg.value = InvUnitInfo.new()
		return _inv_unit_info_msg.value
	
	var _inv_container_req_msg: PBField
	func has_inv_container_req_msg() -> bool:
		return data[101].state == PB_SERVICE_STATE.FILLED
	func get_inv_container_req_msg() -> int:
		return _inv_container_req_msg.value
	func clear_inv_container_req_msg() -> void:
		data[101].state = PB_SERVICE_STATE.UNFILLED
		_inv_container_req_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_inv_container_req_msg(value : int) -> void:
		_dumb_req_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_inv_unit_info_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[100].state = PB_SERVICE_STATE.UNFILLED
		data[101].state = PB_SERVICE_STATE.FILLED
		_inv_container_rsp_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[102].state = PB_SERVICE_STATE.UNFILLED
		_inv_container_req_msg.value = value
	
	var _inv_container_rsp_msg: PBField
	func has_inv_container_rsp_msg() -> bool:
		return data[102].state == PB_SERVICE_STATE.FILLED
	func get_inv_container_rsp_msg() -> InvContainerData:
		return _inv_container_rsp_msg.value
	func clear_inv_container_rsp_msg() -> void:
		data[102].state = PB_SERVICE_STATE.UNFILLED
		_inv_container_rsp_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_inv_container_rsp_msg() -> InvContainerData:
		_dumb_req_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_inv_unit_info_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[100].state = PB_SERVICE_STATE.UNFILLED
		_inv_container_req_msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
		data[101].state = PB_SERVICE_STATE.UNFILLED
		data[102].state = PB_SERVICE_STATE.FILLED
		_inv_container_rsp_msg.value = InvContainerData.new()
		return _inv_container_rsp_msg.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InvNodeUnit:
	func _init():
		var service
		
		_node_width = PBField.new("node_width", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 0, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _node_width
		data[_node_width.tag] = service
		
		_node_height = PBField.new("node_height", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _node_height
		data[_node_height.tag] = service
		
		_node_margin = PBField.new("node_margin", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _node_margin
		data[_node_margin.tag] = service
		
		_container_border_margin = PBField.new("container_border_margin", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _container_border_margin
		data[_container_border_margin.tag] = service
		
	var data = {}
	
	var _node_width: PBField
	func get_node_width() -> float:
		return _node_width.value
	func clear_node_width() -> void:
		data[0].state = PB_SERVICE_STATE.UNFILLED
		_node_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_node_width(value : float) -> void:
		_node_width.value = value
	
	var _node_height: PBField
	func get_node_height() -> float:
		return _node_height.value
	func clear_node_height() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_node_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_node_height(value : float) -> void:
		_node_height.value = value
	
	var _node_margin: PBField
	func get_node_margin() -> float:
		return _node_margin.value
	func clear_node_margin() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_node_margin.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_node_margin(value : float) -> void:
		_node_margin.value = value
	
	var _container_border_margin: PBField
	func get_container_border_margin() -> float:
		return _container_border_margin.value
	func clear_container_border_margin() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_container_border_margin.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_container_border_margin(value : float) -> void:
		_container_border_margin.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InvItemUnit:
	func _init():
		var service
		
		_item_width = PBField.new("item_width", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 0, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _item_width
		data[_item_width.tag] = service
		
		_item_height = PBField.new("item_height", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _item_height
		data[_item_height.tag] = service
		
		_item_margin = PBField.new("item_margin", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _item_margin
		data[_item_margin.tag] = service
		
	var data = {}
	
	var _item_width: PBField
	func get_item_width() -> float:
		return _item_width.value
	func clear_item_width() -> void:
		data[0].state = PB_SERVICE_STATE.UNFILLED
		_item_width.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_item_width(value : float) -> void:
		_item_width.value = value
	
	var _item_height: PBField
	func get_item_height() -> float:
		return _item_height.value
	func clear_item_height() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_item_height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_item_height(value : float) -> void:
		_item_height.value = value
	
	var _item_margin: PBField
	func get_item_margin() -> float:
		return _item_margin.value
	func clear_item_margin() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_item_margin.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_item_margin(value : float) -> void:
		_item_margin.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InvItemData:
	func _init():
		var service
		
		_item_id = PBField.new("item_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 0, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _item_id
		data[_item_id.tag] = service
		
		_item_cols = PBField.new("item_cols", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _item_cols
		data[_item_cols.tag] = service
		
		_item_rows = PBField.new("item_rows", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _item_rows
		data[_item_rows.tag] = service
		
	var data = {}
	
	var _item_id: PBField
	func get_item_id() -> int:
		return _item_id.value
	func clear_item_id() -> void:
		data[0].state = PB_SERVICE_STATE.UNFILLED
		_item_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_item_id(value : int) -> void:
		_item_id.value = value
	
	var _item_cols: PBField
	func get_item_cols() -> int:
		return _item_cols.value
	func clear_item_cols() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_item_cols.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_item_cols(value : int) -> void:
		_item_cols.value = value
	
	var _item_rows: PBField
	func get_item_rows() -> int:
		return _item_rows.value
	func clear_item_rows() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_item_rows.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_item_rows(value : int) -> void:
		_item_rows.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InvContainerData:
	func _init():
		var service
		
		_container_id = PBField.new("container_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 0, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _container_id
		data[_container_id.tag] = service
		
		_container_cols = PBField.new("container_cols", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _container_cols
		data[_container_cols.tag] = service
		
		_container_rows = PBField.new("container_rows", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _container_rows
		data[_container_rows.tag] = service
		
		_occupants = PBField.new("occupants", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _occupants
		service.func_ref = Callable(self, "add_occupants")
		data[_occupants.tag] = service
		
	var data = {}
	
	var _container_id: PBField
	func get_container_id() -> int:
		return _container_id.value
	func clear_container_id() -> void:
		data[0].state = PB_SERVICE_STATE.UNFILLED
		_container_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_container_id(value : int) -> void:
		_container_id.value = value
	
	var _container_cols: PBField
	func get_container_cols() -> int:
		return _container_cols.value
	func clear_container_cols() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_container_cols.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_container_cols(value : int) -> void:
		_container_cols.value = value
	
	var _container_rows: PBField
	func get_container_rows() -> int:
		return _container_rows.value
	func clear_container_rows() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_container_rows.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_container_rows(value : int) -> void:
		_container_rows.value = value
	
	var _occupants: PBField
	func get_occupants() -> Array:
		return _occupants.value
	func clear_occupants() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_occupants.value = []
	func add_occupants() -> InvItemData:
		var element = InvItemData.new()
		_occupants.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InvUnitInfo:
	func _init():
		var service
		
		_node_info = PBField.new("node_info", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 0, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _node_info
		service.func_ref = Callable(self, "new_node_info")
		data[_node_info.tag] = service
		
		_item_info = PBField.new("item_info", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _item_info
		service.func_ref = Callable(self, "new_item_info")
		data[_item_info.tag] = service
		
	var data = {}
	
	var _node_info: PBField
	func get_node_info() -> InvNodeUnit:
		return _node_info.value
	func clear_node_info() -> void:
		data[0].state = PB_SERVICE_STATE.UNFILLED
		_node_info.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_node_info() -> InvNodeUnit:
		_node_info.value = InvNodeUnit.new()
		return _node_info.value
	
	var _item_info: PBField
	func get_item_info() -> InvItemUnit:
		return _item_info.value
	func clear_item_info() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_item_info.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_item_info() -> InvItemUnit:
		_item_info.value = InvItemUnit.new()
		return _item_info.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################
