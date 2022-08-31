class Dog
  attr_accessor :name, :breed, :id

  def initialize(id: nil, name:, breed:)
    @name = name
    @breed = breed
    # NOTE: This is needed especially for the '.new_from_db' method later on:
    @id = id
  end

  def self.create_table()
    sql = <<-SQL
CREATE TABLE IF NOT EXISTS dogs (
id INTEGER PRIMARY KEY,
name TEXT,
breed TEXT
)
SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table()
    # NOTE: This SQL statement itself was gained by looking at the corresponding test itself
    # since they never went over how to make an actual SQL statement to 'drop' a table:
    # FROM THE RELATED TEST:
    # table_check_sql = "SELECT tbl_name FROM sqlite_master WHERE type='table' AND tbl_name='dogs';"
    # expect(DB[:conn].execute(table_check_sql)[0]).to eq(nil)
    # Related reference for 'DROP TABLE':
    # https://www.sqlitetutorial.net/sqlite-drop-table/
    sql = <<-SQL
DROP TABLE IF EXISTS dogs
SQL
    DB[:conn].execute(sql)
  end

  def save()
    # NOTE: We are using '?' so that we can insert the Class instance's values accordingly:
    sql = <<-SQL
INSERT INTO dogs(name, breed)
VALUES(?, ?)
SQL
    # NOTE: Here are executing the SQL statement to actually save it to the database:
    DB[:conn].execute(sql, self.name, self.breed)
    # Related reference for 'last_insert_rowid()' method for Sqlite:
    # https://www.w3resource.com/sqlite/core-functions-last_insert_rowid.php
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    self
  end

  def self.create(name:, breed:)
    dog = Dog.new(name: name, breed: breed)
    dog.save
  end

  # NOTE: We have to pass in the given 'row' which would be the class instance in this case
  # aka the individual dog record:
  def self.new_from_db(row)
    # self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    self.new(id: row[0], name: row[1], breed: row[2])
  end

  def self.all
    sql = <<-SQL
SELECT *
FROM dogs
SQL
    # NOTE: Here we iterate through all of the rows we return
    DB[:conn].execute(sql).map do |row|
      # NOTE: Then, we create a new Class instance from the returned data for that given row:
      self.new_from_db(row)
    end
  end

  def self.find_by_name(name)
    sql = <<-SQL
SELECT *
FROM dogs
WHERE name = ?
LIMIT 1
SQL
    # NOTE: This is the way I understand this section:
    # We execute the above SQL statement and also provide the name that we passed in as a parameter
    # After this, we iterate through the returned array since we can then use .map() on it
    # to iterate through each row
    DB[:conn].execute(sql, name).map do |row|
      # Within each row, we can then call the '.new_from_db' method:
      self.new_from_db(row)
      # NOTE: Here we are using chaining so that we can just end on the first result we iterated through:
    end.first
  end

  # NOTE: I completely guessed that 'self.find()' was exactly like 'self.find_by_name()' and
  # I was right since it's the same idea but utilizing an 'id' attribute instead:
  def self.find(id)
    sql = <<-SQL
SELECT *
FROM dogs
WHERE id = ?
LIMIT 1
SQL
    DB[:conn].execute(sql, id).map do |row|
      self.new_from_db(row)
    end.first
  end
end
