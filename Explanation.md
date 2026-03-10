
# Bug Explanation

## 1. What was the bug?

When `oauth2Token` was set to a plain object (e.g. `{ accessToken: "stale", expiresAt: 0 }`), the `request` method neither refreshed the token nor set the `Authorization` header, so the API call went out unauthenticated.

## 2. Why did it happen?

The refresh condition was:

```typescript
!this.oauth2Token || (this.oauth2Token instanceof OAuth2Token && this.oauth2Token.expired)
```

A plain object is truthy, so `!this.oauth2Token` is `false`. The second branch also short-circuits because the plain object fails `instanceof OAuth2Token`. The token looked "present" to the guard, so refresh was skipped. Then the header-assignment block — also gated on `instanceof OAuth2Token` — was skipped too. Result: no refresh, no header.

## 3. Why does the fix actually solve it?

The new condition flips the logic to *require* a valid instance rather than merely a truthy value:

```typescript
!(this.oauth2Token instanceof OAuth2Token) || this.oauth2Token.expired
```

Now anything that isn't a proper `OAuth2Token` — `null`, a plain object, or any other stray value — triggers a refresh. After the refresh, `oauth2Token` is guaranteed to be a real `OAuth2Token`, so the header-assignment block runs correctly.

## 4. What's one realistic edge case the tests still don't cover?

**Concurrent requests racing on a stale token.** If two calls hit `request()` simultaneously while the token is expired, both will pass the refresh check and call `refreshOAuth2()` in parallel. Depending on the real implementation (e.g. an async network call), this could fire two refresh requests and cause a race where the second overwrites or invalidates the first. The current tests are synchronous and single-threaded, so this scenario is invisible to them.
