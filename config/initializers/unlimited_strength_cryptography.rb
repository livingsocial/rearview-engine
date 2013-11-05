# Only for non-production environments. For production systems install the correct jurisdiction jars:
# https://github.com/jruby/jruby/wiki/UnlimitedStrengthCrypto
if !Rails.env.production?
  java.lang.Class.for_name('javax.crypto.JceSecurity').get_declared_field('isRestricted').tap{|f| f.accessible = true; f.set nil, false}
end
