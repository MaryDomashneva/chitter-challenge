require_relative 'db_connection'
require 'bcrypt'

class User
  extend DbConnection
  attr_reader :id, :email, :password, :user_name

  def initialize(id:, email:, user_name:)
    @id = id
    @email = email
    @user_name = user_name
  end

  def self.all
    connection.exec("SELECT * FROM users;").to_a.map do |user|
      User.new(
        id: user['id'],
        email: user['email'],
        user_name: user['user_name']
      )
    end
  end

  def self.create(user_name:, email:, password:)
    password = BCrypt::Password.create(password)
    result = connection.exec(
      "INSERT INTO users (user_name, email, password)
      VALUES('#{user_name}', '#{email}', '#{password}')
      RETURNING id, email;"
    )
    User.new(
      id: result[0]['id'],
      email: result[0]['email'],
      user_name: result[0]['user_name']
    )
  end

  def self.update(id:, user_name:, email:)
    result = connection.exec(
      "UPDATE users
      SET user_name = '#{user_name}', email = '#{email}'
      WHERE id = #{id} RETURNING id, email, user_name;"
    )
    User.new(
      id: result[0]['id'],
      email: result[0]['email'],
      user_name: result[0]['user_name']
    )
  end

  def self.find(id)
    result = connection.exec(
      "SELECT * FROM users
      WHERE id = #{id};"
    )
    User.new(
      id: result[0]['id'],
      email: result[0]['email'],
      user_name: result[0]['user_name']
    )
  end

  def self.login(email:, password:)
    result = connection.exec(
      "SELECT * FROM users
      WHERE email = '#{email}';"
    )
    return unless result.any?
    return unless BCrypt::Password.new(result[0]['password']) == password
    User.new(
      id: result[0]['id'],
      email: result[0]['email'],
      user_name: result[0]['user_name']
    )
  end

  def self.unique?(user_name:, email:)
    result = connection.exec(
      "SELECT * FROM users
      WHERE user_name = '#{user_name}'
      OR email = '#{email}';"
    )
    result.to_a.length.zero?
  end

  def self.unique_user_name?(user_name:)
    result = connection.exec(
      "SELECT * FROM users
      WHERE user_name = '#{user_name}';"
    )
    result.to_a.length.zero?
  end

  def self.unique_user_email?(email:)
    result = connection.exec(
      "SELECT * FROM users
      WHERE email = '#{email}';"
    )
    result.to_a.length.zero?
  end
end
