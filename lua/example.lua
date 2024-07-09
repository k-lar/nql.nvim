local nql = require("my_plugins.nql.lua.nql")

-- nql.query(DataType.Tasks):from("utils.lua")
nql.query(DataType.Tasks):from("test/test1.md"):limit(2)
-- nql.query(DataType.Tasks):limit(1)
