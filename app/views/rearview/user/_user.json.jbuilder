json.(user,:id,:email,:first_name,:last_name,:preferences)
json.lastLogin user.last_login.to_i
json.createdAt user.created_at.to_i
json.modifiedAt user.updated_at.to_i
