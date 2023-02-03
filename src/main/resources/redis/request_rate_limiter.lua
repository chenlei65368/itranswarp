-- copied from https://github.com/spring-cloud/spring-cloud-gateway/blob/master/spring-cloud-gateway-core/src/main/resources/META-INF/scripts/request_rate_limiter.lua
-- RedisRateLimiter 限流脚本
local tokens_key = KEYS[1]  -- 存放令牌数量的key
local timestamp_key = KEYS[2]  -- 存放最近一次拿令牌的时间
--redis.log(redis.LOG_WARNING, "tokens_key " .. tokens_key)

local rate = tonumber(ARGV[1])  -- 每秒往桶里放的令牌数
local capacity = tonumber(ARGV[2])  -- 桶最大容量
local now = tonumber(ARGV[3])       -- 当前时间
local requested = tonumber(ARGV[4])  -- 每次算几个令牌

local fill_time = capacity/rate    -- 从零开始多久满
local ttl = math.floor(fill_time*2)  -- key的存活时间，如果过了这个时间，肯定就满了，每必要存了

--redis.log(redis.LOG_WARNING, "rate " .. ARGV[1])
--redis.log(redis.LOG_WARNING, "capacity " .. ARGV[2])
--redis.log(redis.LOG_WARNING, "now " .. ARGV[3])
--redis.log(redis.LOG_WARNING, "requested " .. ARGV[4])
--redis.log(redis.LOG_WARNING, "filltime " .. fill_time)
--redis.log(redis.LOG_WARNING, "ttl " .. ttl)

local last_tokens = tonumber(redis.call("get", tokens_key))  -- 目前桶里的令牌数
if last_tokens == nil then
  last_tokens = capacity
end
--redis.log(redis.LOG_WARNING, "last_tokens " .. last_tokens)

local last_refreshed = tonumber(redis.call("get", timestamp_key))  --最近一次取令牌的时间
if last_refreshed == nil then
  last_refreshed = 0
end
--redis.log(redis.LOG_WARNING, "last_refreshed " .. last_refreshed)

local delta = math.max(0, now-last_refreshed)              --上次取令牌到现在过了多少秒
local filled_tokens = math.min(capacity, last_tokens+(delta*rate))  -- 放新令牌后的总数
local allowed = filled_tokens >= requested           -- 现在桶里令牌够不够执行一次
local new_tokens = filled_tokens                     -- 当前令牌数
local allowed_num = 0
if allowed then
  new_tokens = filled_tokens - requested             -- 拿走一次令牌后剩余令牌数
  allowed_num = 1
end

--redis.log(redis.LOG_WARNING, "delta " .. delta)
--redis.log(redis.LOG_WARNING, "filled_tokens " .. filled_tokens)
--redis.log(redis.LOG_WARNING, "allowed_num " .. allowed_num)
--redis.log(redis.LOG_WARNING, "new_tokens " .. new_tokens)

redis.call("setex", tokens_key, ttl, new_tokens)     -- 更新令牌数
redis.call("setex", timestamp_key, ttl, now)         -- 更新最后一次执行时间

--IMPORTANT: modified: only return how many remaining + 1:
--return { allowed_num, new_tokens }

if allowed_num == 0 then
  return 0
else
  return new_tokens + 1
end
