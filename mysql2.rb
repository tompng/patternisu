query = 'select * from users where id < 4'
client.xquery(query, symbolize_keys: true).to_a
client.xquery(query, as: :array).to_a
