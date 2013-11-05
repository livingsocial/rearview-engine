
json.(dashboard,:id,:user_id,:name,:description)
json.createdAt dashboard.created_at.to_i
json.modifiedAt dashboard.updated_at.to_i
json.children dashboard.children do |child|
  json.(child,:id,:user_id,:name,:description)
  json.createdAt dashboard.created_at.to_i
  json.modifiedAt dashboard.updated_at.to_i
end


