/**
  Encapsulates switching between various output formats
 */
module serializer;

import sam.serialize;
import samheader;
import jsonserialization;
import utils.format;
import std.exception;
import alignment;
import reference;

private {
    import std.c.stdio : stdout;
    import std.json;

    interface AlignmentSerializer {
        void writeln(Alignment a, ReferenceSequenceInfo[] info);
        void writeln(SamHeader header);
    }

    final class SamSerializer : AlignmentSerializer {
        void writeln(Alignment a, ReferenceSequenceInfo[] info) {
            serialize(a, info, stdout);
            putcharacter(stdout, '\n');
        }
        void writeln(SamHeader header) {
            putstring(stdout, header.text);
        }
    }

    final class JsonSerializer : AlignmentSerializer {
        void writeln(Alignment a, ReferenceSequenceInfo[] info) {
            jsonSerialize(a, info, stdout);
            putcharacter(stdout, '\n');
        }

        void writeln(SamHeader header) {
            
            static JSONValue jv(T)(T value) {
                JSONValue v;
                static if(is(T == string)) {
                    v.str = value;
                    v.type = JSON_TYPE.STRING;
                } else static if(is(T == uint)) {
                    v.integer = value;
                    v.type = JSON_TYPE.INTEGER;
                }
                return v;
            }

            JSONValue result;
            result.type = JSON_TYPE.OBJECT;

            if (header.hasHeaderLine()) {
                result.object["format_version"] = jv(header.format_version);
                result.object["sorting_order"] = jv(header.sorting_order);
            }

            JSONValue tmp;
            tmp.type = JSON_TYPE.ARRAY;
            tmp.array = new JSONValue[header.sq_lines.length];
            foreach (size_t i, line; header.sq_lines) {
                JSONValue sq;
                sq.type = JSON_TYPE.OBJECT;
                sq.object["sequence_name"] = jv(line.sequence_name);
                sq.object["sequence_length"] = jv(line.sequence_length);
                sq.object["assembly"] = jv(line.assembly);
                sq.object["md5"] = jv(line.md5);
                sq.object["species"] = jv(line.species);
                sq.object["uri"] = jv(line.uri);
                tmp.array[i] = sq;
            }
            result.object["sq_lines"] = tmp;

            tmp.array.length = header.rg_lines.length;
            foreach (size_t i, line; header.rg_lines) {
                JSONValue sq;
                sq.type = JSON_TYPE.OBJECT;
                sq.object["identifier"] = jv(line.identifier);
                sq.object["sequencing_center"] = jv(line.sequencing_center);
                sq.object["description"] = jv(line.description);
                sq.object["date"] = jv(line.date);
                sq.object["flow_order"] = jv(line.flow_order);
                sq.object["key_sequence"] = jv(line.key_sequence);
                sq.object["library"] = jv(line.library);
                sq.object["programs"] = jv(line.programs);
                sq.object["predicted_insert_size"] = jv(line.predicted_insert_size);
                sq.object["platform"] = jv(line.platform);
                sq.object["platform_unit"] = jv(line.platform_unit);
                sq.object["sample"] = jv(line.sample);
                tmp.array[i] = sq;
            }
            result.object["rg_lines"] = tmp;

            tmp.array.length = header.pg_lines.length;
            foreach (size_t i, line; header.pg_lines) {
                JSONValue sq;
                sq.type = JSON_TYPE.OBJECT;
                sq.object["identifier"] = jv(line.identifier);
                sq.object["program_name"] = jv(line.program_name);
                sq.object["command_line"] = jv(line.command_line);
                sq.object["previous_program"] = jv(line.previous_program);
                sq.object["program_version"] = jv(line.program_version);
               tmp.array[i] = sq;
            }
            result.object["rg_lines"] = tmp;

            putstring(stdout, toJSON(&result));
            putcharacter(stdout, '\n');
        }
    }
}

final class Serializer {
    private AlignmentSerializer _serializer;

    this(string format) {
        switch(format) {
            case "sam":
                _serializer = new SamSerializer(); break;
            case "json":
                _serializer = new JsonSerializer(); break;
            default:
                throw new Exception("unknown format for serialization: '" ~ format ~ 
                                    "' (expected 'sam' or 'json')");
        }
    }

    void writeln(Alignment a, ReferenceSequenceInfo[] info) {
        _serializer.writeln(a, info);
    }

    void writeln(SamHeader header) {
        _serializer.writeln(header);
    }
}
