# TMDB setup

WATCHLIST uses The Movie Database (TMDB) for catalogue metadata. The app sends requests to the v3 API using a **Bearer API Read Access Token**.

## Configure locally

1. Create or sign in to a TMDB account and request an API key for your application.
2. In Xcode, open the generated WATCHLIST project.
3. Select the WATCHLIST target and its Info settings.
4. Add a string key named `TMDBAccessToken` with your API Read Access Token as its value.
5. Keep the token out of source control, screenshots and public build logs.

The repository intentionally contains no working token. A missing token is reported as a configuration error rather than silently making an unauthenticated request.

## Request defaults

- Locale: `sv-SE`
- Region: `SE`
- Adult results: excluded
- Search endpoints: `/search/movie` and `/search/tv`
- Authentication: HTTP Bearer token

## Attribution

WATCHLIST is not endorsed or certified by TMDB. Any public release must include the current TMDB logo and attribution wording required by the TMDB API terms. Review the current TMDB terms before distributing builds.

## Architecture

The `MediaSearching` protocol isolates feature code from the concrete `TMDBClient`. Tests and previews can inject a fake implementation without making network requests.
