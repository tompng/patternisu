# frozen_string_literal: true
require 'mysql2'

@statements = {}
def statement sql
  @statements[sql] ||= db.prepare sql
end

statement(
  'INSERT INTO foobars (foo_id, bar_id, aaa) VALUES (?, ?, ?)'
).execute(foo_id, bar_id, aaa)
