package com.itranswarp.redis;

import java.util.concurrent.CompletableFuture;

import io.lettuce.core.api.async.RedisAsyncCommands;

@FunctionalInterface  // 函数接口注解
public interface BatchAsyncCommandCallback<T> {

    CompletableFuture<T> doInConnection(RedisAsyncCommands<String, String> commands);
}
