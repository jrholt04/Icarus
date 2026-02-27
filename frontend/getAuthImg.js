
function getAuthorImage(apiKey, authorName) {
  const query = `
  {
    authors(where: {
      name: {_eq: "${authorName}"}
    	image_id: {_is_null: false}
    }) {
      name
      image {
        url
      }
      user_id
    }
  }`;

  return fetch('https://api.hardcover.app/v1/graphql', {
      headers: {
          'content-type': 'application/json',
          authorization: apiKey,
      },
      body: JSON.stringify({ query }),
      method: 'POST',
  })
    .then((response) => response.json())
    .then(({ data }) => {
      const authors = data?.authors ?? [];
      return authors.map((author) => ({
        name: author.name,
        imageUrl: author.image?.url ?? null,
        userId: author.user_id,
      }));
    });
}

function renderAuthorImage(apiKey, authorName, imgEl) {
  if (!apiKey || !authorName || !imgEl) return Promise.resolve(null);
  return getAuthorImage(apiKey, authorName).then((authors) => {
    const url = authors?.[0]?.imageUrl ?? null;
    if (url) imgEl.src = url;
    return url;
  });
}

window.getAuthorImage = getAuthorImage;
window.renderAuthorImage = renderAuthorImage;
