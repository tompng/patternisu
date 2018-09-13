require 'mysql2-cs-bind'

# only insert pattern
def load_new_comments
  return unless @last_comment_id < redis.get('last_comment_id').to_i # optional
  new_comments = db.xquery('select * from comments where id > ?', @last_comment_id).to_a
  new_comments.each do |comment|
    @comments_by_id[comment[:id]] = @comments_by_user[comment[:user_id]] = comment
  end
  @last_comment_id = new_comments.last[:id]
end
Thread.new { loop { load_new_comments; sleep 1 } } # optional

# changes table pattern
comment.update params
db.xquery 'update comments set body = ? where id = ?', comment_body, comment_id
db.xquery(
  'insert into changed_records (model_name, model_id, mode) values (?, ?, ?)',
  :comments, comment_id, :updated
)
redis.set 'last_changes_id', db.last_id

# redis changes list pattern
changes_index = 0
post '/update' do
  db.xquery('update users ...', id)
  redis.rpush 'changes', Oj.dump(['users', id])
end
get '/' do
  idx = changes_index
  changes = redis.lrange 'changes', idx, -1
  changes.each { |data| read_from_db_and_cache_to_memory data }
  changes_index = idx + changes.size
end

# broadcast pattern
db.xquery 'update comments set body = ? where id = ?', comment_body, comment_id
redis.publish 'comments_changed', Oj.dump(id: comment_id, body: comment_body)

# redis aggregate pattern
redis.set "last_comment_id_#{worker_id}", last_comment_id
last_comment_id = redis.mget(worker_ids.map { |id| "last_comment_id_#{id}" }).map(&:to_i).max

# third normal form
Comment.attribute_names #=> %w[user_id post_id body] # too large to cache on memory
Comment.attribute_names #=> %w[user_id post_id body_id] # can cache on memory
CommentBody.attribute_names #=> %w[id body] # unique_index on body
def id_from_comment_body body
  @id_from_comment_body[body] ||= begin
    CommentBody.create(body: body).id
  rescue
    CommentBody.where(body: body).first.id
  end
end
