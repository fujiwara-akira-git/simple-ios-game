import React, { useEffect, useRef, useState } from 'react'
import Head from 'next/head'

type Circle = {
  x: number
  y: number
  size: number
}

export default function Home(): JSX.Element {
  const [score, setScore] = useState<number>(0)
  const [timeLeft, setTimeLeft] = useState<number>(30)
  const [gameRunning, setGameRunning] = useState<boolean>(false)
  const [circle, setCircle] = useState<Circle>({ x: 50, y: 50, size: 80 })
  const [bestScore, setBestScore] = useState<number>(0)

  const intervalRef = useRef<number | null>(null)

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const s = localStorage.getItem('simple-tap-game-best')
      if (s) setBestScore(Number(s))
    }
  }, [])

  useEffect(() => {
    if (gameRunning) {
      intervalRef.current = window.setInterval(() => {
        setTimeLeft(t => {
          if (t <= 1) {
            setGameRunning(false)
            if (intervalRef.current) {
              clearInterval(intervalRef.current)
              intervalRef.current = null
            }
            return 0
          }
          return t - 1
        })
      }, 1000)
    }
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current)
        intervalRef.current = null
      }
    }
  }, [gameRunning])

  useEffect(() => {
    if (!gameRunning && timeLeft === 0) {
      if (score > bestScore) {
        setBestScore(score)
        if (typeof window !== 'undefined') {
          localStorage.setItem('simple-tap-game-best', String(score))
        }
      }
    }
  }, [gameRunning, timeLeft, score, bestScore])

  function startGame() {
    setScore(0)
    setTimeLeft(30)
    setGameRunning(true)
    moveCircle()
  }

  function moveCircle() {
    const size = Math.floor(40 + Math.random() * 80)
    let x = 50
    let y = 50
    if (typeof window !== 'undefined') {
      x = Math.floor(Math.random() * Math.max(1, window.innerWidth - size))
      y = Math.floor(Math.random() * Math.max(1, window.innerHeight - size - 120)) + 100
    }
    setCircle({ x, y, size })
  }

  function handleTap() {
    if (!gameRunning) return
    setScore(s => s + 1)
    moveCircle()
  }

  return (
    <div className="page">
      <Head>
        <title>Simple Tap Game</title>
      </Head>
      <header className="header">
        <div>Score: {score}</div>
        <div>Time: {timeLeft}s</div>
      </header>

      <main className="main" onClick={() => { /* click outside does nothing */ }}>
        {!gameRunning && timeLeft === 0 && (
          <div className="overlay">
            <div className="overlay-card">
              <h2>Time's up</h2>
              <p>Your score: {score}</p>
              <p>Best: {bestScore}</p>
              <button onClick={startGame}>Restart</button>
            </div>
          </div>
        )}

        {!gameRunning && timeLeft > 0 && (
          <div className="center-start">
            <button className="start-btn" onClick={startGame}>Start Game</button>
          </div>
        )}

        {gameRunning && (
          <div
            className="circle"
            onClick={handleTap}
            style={{
              width: circle.size + 'px',
              height: circle.size + 'px',
              left: circle.x + 'px',
              top: circle.y + 'px'
            }}
          />
        )}
      </main>
    </div>
  )
}
