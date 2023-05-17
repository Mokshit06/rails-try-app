import clsx from 'clsx';
import { useRouter } from 'next/router';
import { useEffect, useRef, useState } from 'react';

function randomInteger(min: number, max: number) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

type QuestionProps = {
  defaultQuestion: string;
  defaultAnswer?: string;
  audioSrcUrl?: string;
};

export function Question({
  defaultQuestion,
  defaultAnswer = '',
  audioSrcUrl = '',
}: QuestionProps) {
  const router = useRouter();

  const audioRef = useRef<HTMLAudioElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const timeoutRef = useRef<number>();

  const [question, setQuestion] = useState(defaultQuestion);
  const [isLoading, setLoading] = useState(false);
  const [answer, setAnswer] = useState(defaultAnswer);
  const [sourceURL, setSourceURL] = useState(audioSrcUrl);

  useEffect(() => {
    return () => {
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
    };
  }, []);

  const resetAnswer = () => {
    if (timeoutRef.current) clearTimeout(timeoutRef.current);
    setAnswer('');
  };

  const handleSubmit: React.FormEventHandler = async e => {
    e.preventDefault();

    if (question === '') {
      alert('Please ask a question!');
      return;
    }

    setLoading(true);

    const result = await fetch(`${process.env.NEXT_PUBLIC_RAILS_URL}/ask`, {
      method: 'post',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ question }),
    }).then(r => r.json());

    const tick = (index: number) => {
      if (index < result.answer.length) {
        const interval = randomInteger(30, 70);
        setAnswer(p => p + result.answer[index++]);

        setTimeout(() => tick(index), interval);
      } else {
        router.push(`/question/${result.id}`);
      }
    };

    timeoutRef.current = setTimeout(() => tick(0), 1200) as any;

    if (result.audio_src_url) {
      setSourceURL(result.audio_src_url);
      const audio = audioRef.current!;
      audio.volume = 0.3;
      audio.play();
    }

    setLoading(false);

    router.push(`/question/${result.id}`, undefined, { shallow: true });
  };

  return (
    <>
      <div className="header">
        <div className="logo">
          <a href="https://www.amazon.com/Minimalist-Entrepreneur-Great-Founders-More/dp/0593192397">
            <img src="/book.png" loading="lazy" />
          </a>
          <h1>Ask My Book</h1>
        </div>
      </div>
      <div className="main">
        <p className="credits">
          This is an experiment in using AI to make my book's content more
          accessible. Ask a question and AI'll answer it in real-time:
        </p>
        <form action="/ask" method="post" onSubmit={handleSubmit}>
          <textarea
            name="question"
            ref={textareaRef}
            value={question}
            onChange={e => {
              setQuestion(e.target.value);
              resetAnswer();
            }}
          />
          <div
            className="buttons"
            style={{ display: answer ? 'none' : undefined }}
          >
            <button type="submit" disabled={isLoading}>
              {isLoading ? 'Asking...' : 'Ask question'}
            </button>
            <button
              style={{ background: '#eee', borderColor: '#eee', color: '#444' }}
              onClick={() => {
                const options = [
                  'What is a minimalist entrepreneur?',
                  'What is your definition of community?',
                  'How do I decide what kind of business I should start?',
                ];
                const random = Math.floor(Math.random() * options.length);

                setQuestion(options[random]);
              }}
            >
              I'm feeling lucky
            </button>
          </div>
        </form>

        <p className={clsx('hidden', answer && 'showing')}>
          <strong>Answer:</strong> <span>{answer}</span>{' '}
          <button
            style={{ display: answer ? 'block' : 'none' }}
            onClick={() => {
              audioRef.current?.pause();
              resetAnswer();
              textareaRef.current?.select();
            }}
          >
            Ask another question
          </button>
        </p>

        <audio ref={audioRef} controls autoPlay>
          <source src={sourceURL} type="audio/wav" />
        </audio>
      </div>
      <footer>
        <p className="credits">
          Project by <a href="https://twitter.com/mokshit06">Mokshit06</a> •{' '}
          <a href="https://github.com/mokshit06/askmybook">Fork on GitHub</a>
        </p>
      </footer>
    </>
  );
}
