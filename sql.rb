# last posts for each user
db.xquery(<<SQL, user_ids)
  SELECT posts.* FROM posts WHERE posts.id IN (
    SELECT max(id) FROM posts WHERE posts.user_id IN (?) GROUP BY posts.user_id
  )
SQL

# last posts for each user except exclude_post_ids
db.xquery(<<SQL, user_ids, exclude_post_ids)
  SELECT posts.* FROM posts WHERE posts.id IN (
    SELECT max(id) FROM posts WHERE posts.user_id IN (?) AND posts.id NOT IN (?) GROUP BY posts.user_id
  )
SQL

# last #{limit} posts for each user
db.xquery(<<SQL, user_ids)
  SELECT posts.*, top_n_group_key
  FROM users INNER JOIN posts ON posts.user_id = users.id
  INNER JOIN
  (
    SELECT T.id as top_n_group_key,
    (
      SELECT posts.id
      FROM users INNER JOIN posts ON posts.user_id = users.id
      WHERE users.id = T.id
      ORDER BY posts.id DESC
      LIMIT 1 OFFSET #{limit - 1}
    ) AS last_value
    FROM users as T where T.id in (?)
  ) T
  ON users.id = T.top_n_group_key
  AND (
    T.last_value IS NULL
    OR posts.id >= T.last_value
  )
SQL

# last #{limit} posts for each user_ids
db.query(<<SQL)
  SELECT posts.*, top_n_group_key
  FROM posts
  INNER JOIN
  (
    SELECT top_n_group_key,
    (
      SELECT posts.id FROM posts
      WHERE posts.user_id = T.top_n_group_key
      ORDER BY posts.id DESC
      LIMIT 1 OFFSET #{limit - 1}
    ) AS last_value
    FROM (SELECT 1 AS top_n_group_key
      #{user_ids.map { |a| "UNION SELECT #{a}" }.join ' '}
    ) AS T
  ) T
  ON posts.user_id = T.top_n_group_key
  AND (
    T.last_value IS NULL
    OR posts.id >= T.last_value
    OR posts.id is NULL
  )
SQL
