import { useEffect, useState } from 'react'
import { getGroupTiles, getRecent, getRandom, imageUrl } from './api/jellyfin'

function Card({ item }) {
  const [type, setType] = useState('Backdrop')
  return (
    <div className="card" tabIndex={0}>
      <img
        src={imageUrl(item.Id, type)}
        alt={item.Name}
        loading="lazy"
        onError={() => type === 'Backdrop' && setType('Primary')}
      />
      <div className="card-title">
        {item.Name}
        {item.ProductionYear ? <span className="year"> · {item.ProductionYear}</span> : null}
      </div>
    </div>
  )
}

function Shelf({ title, items }) {
  if (!items?.length) return null
  return (
    <section className="shelf">
      <h2>{title}</h2>
      <div className="row">
        {items.map((i) => (
          <Card key={i.Id} item={i} />
        ))}
      </div>
    </section>
  )
}

export default function App() {
  const [tiles, setTiles] = useState([])
  const [recent, setRecent] = useState([])
  const [rand, setRand] = useState([])
  const [err, setErr] = useState(null)

  useEffect(() => {
    ;(async () => {
      try {
        const [t, r, rr] = await Promise.all([getGroupTiles(), getRecent(), getRandom()])
        setTiles(t)
        setRecent(r)
        setRand(rr)
      } catch (e) {
        setErr(e.message)
      }
    })()
  }, [])

  if (err) {
    return (
      <div className="error">
        <h2>Couldn’t reach Jellyfin</h2>
        <p>{err}</p>
        <p className="hint">
          Check <code>.env</code> (URL / token / user id) and that the dev proxy target in{' '}
          <code>vite.config.js</code> points at your server.
        </p>
      </div>
    )
  }

  const hero = recent[0]

  return (
    <div className="app">
      {hero && (
        <header className="hero" style={{ backgroundImage: `url(${imageUrl(hero.Id, 'Backdrop')})` }}>
          <div className="hero-fade" />
          <div className="hero-inner">
            <h1>{hero.Name}</h1>
            {hero.Overview && <p>{hero.Overview.slice(0, 240)}</p>}
            <div className="hero-actions">
              <button className="play">▶ Play</button>
              <button className="more">＋ My List</button>
            </div>
          </div>
        </header>
      )}

      <main>
        <Shelf title="Browse the Collection" items={tiles} />
        <Shelf title="Recently Added" items={recent} />
        <Shelf title="Surprise Me" items={rand} />
      </main>

      <footer className="foot">Bruno · proof of concept · {tiles.length} pinned collections</footer>
    </div>
  )
}
