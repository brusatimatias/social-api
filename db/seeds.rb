# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with bin/rails db:seed or created alongside the database with db:setup.
#
# Safe to run multiple times: it only creates data on a fresh database (no users yet).
if User.exists?
  puts "Database already has users, skipping seed. Run `rails db:reset` first if you want fresh seed data."
  return
end

PASSWORD = "password".freeze

puts "Creating users..."
users = %w[
  Ada:Lovelace:ada@example.com
  Grace:Hopper:grace@example.com
  Katherine:Johnson:katherine@example.com
  Alan:Turing:alan@example.com
  Margaret:Hamilton:margaret@example.com
].to_h do |entry|
  name, lastname, email = entry.split(":")
  user = User.create!(
    name: name,
    lastname: lastname,
    email: email,
    password: PASSWORD,
    password_confirmation: PASSWORD
  )
  [name.to_sym, user]
end

ada, grace, katherine, alan, margaret = users.values_at(:Ada, :Grace, :Katherine, :Alan, :Margaret)

puts "Creating follow relationships..."
{
  ada => [grace, katherine],
  grace => [ada, alan],
  katherine => [ada, margaret],
  alan => [grace, margaret],
  margaret => [katherine, alan]
}.each do |follower, followees|
  followees.each { |followee| follower.following_relationships.create!(following: followee) }
end

puts "Creating posts..."
posts = [
  ada.posts.create!(content: "Just published my notes on the Analytical Engine.", visibility: :public,
    status: :published),
  ada.posts.create!(content: "Draft: thoughts on algorithms (not ready yet).", visibility: :public,
    status: :draft),
  ada.posts.create!(content: "Private notes to self.", visibility: :private, status: :published),
  grace.posts.create!(content: "Found another bug. Literally.", visibility: :public, status: :published),
  grace.posts.create!(content: "Followers-only update on the COBOL compiler.", visibility: :followers,
    status: :published),
  katherine.posts.create!(content: "Orbital mechanics calculations checked twice.", visibility: :public,
    status: :published),
  katherine.posts.create!(content: "Old post I archived.", visibility: :public, status: :archived),
  alan.posts.create!(content: "Followers-only: progress on the machine.", visibility: :followers,
    status: :published),
  alan.posts.create!(content: "Public post about computable numbers.", visibility: :public,
    status: :published),
  margaret.posts.create!(content: "Public: our onboard flight software shipped today!", visibility: :public,
    status: :published),
  margaret.posts.create!(content: "Private retrospective notes.", visibility: :private, status: :published)
]

avatar_path = Rails.root.join("spec/fixtures/files/avatar.png")
posts.first.media.attach(io: File.open(avatar_path), filename: "avatar.png", content_type: "image/png")

puts "Creating comments..."
[
  [grace, posts[0], "This is fascinating, Ada!"],
  [katherine, posts[0], "Would love to see the full notes."],
  [ada, posts[3], "Story of my life."],
  [alan, posts[5], "Impressive precision as always."],
  [margaret, posts[8], "Computable numbers are the foundation of it all."]
].each { |author, post, content| author.comments.create!(post: post, content: content) }

puts "Creating likes..."
[
  [grace, posts[0]], [katherine, posts[0]], [alan, posts[0]],
  [ada, posts[3]], [margaret, posts[5]],
  [grace, posts[8]], [katherine, posts[9]], [ada, posts[9]]
].each { |user, post| user.likes.create!(post: post) }

puts <<~SUMMARY

  Seed complete: #{User.count} users, #{Post.count} posts, #{Comment.count} comments, #{Like.count} likes.
  Every user's password is "#{PASSWORD}", e.g. log in as ada@example.com / #{PASSWORD}.
SUMMARY
