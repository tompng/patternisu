connection = ActiveRecord::Base.connection
connection.create_table :comments
connection.add_column :comments, :user_id, :integer
connection.add_index :comments, :user_id
connection.add_index :comments, [:post_id, :user_id], unique: true
connection.execute 'alter table comments character set utf8'
connection.remove_column :comments, :post_id
connection.drop_table :comments
