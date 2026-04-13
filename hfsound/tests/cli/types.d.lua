--- marker alias to indicate that a string is to be treated as bytes in some
--- encoding
---@alias bytes string

--- marker alias to indicate a string that contains a single character in some
--- encoding
---@alias char bytes
---@alias hf.Provider<T> fun():T

---@alias hf.Encoding.Length    fun(s:bytes): integer
---@alias hf.Encoding.Slice     fun(s:bytes, from:integer, to?:integer): bytes
---@alias hf.Encoding.Offset    fun(s:bytes, i:integer, start?:integer): integer


---@class hf.Encoding # { len: hf.Encoding.Length, sub: hf.Encoding.Slice, offset: hf.Encoding.Offset }
---@field len       fun(s:bytes): integer
---@field offset    fun(s:bytes, i:integer, start?:integer): integer
