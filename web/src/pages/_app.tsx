import '@/styles/globals.css';
import type { AppProps } from 'next/app';
import Head from 'next/head';

export default function App({ Component, pageProps }: AppProps) {
  return (
    <>
      <Head>
        <title>Ask My Book: The Minimalist Entrepreneur</title>
        <link rel="shortcut icon" href="/favicon.svg" />
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:site" content="@mokshit06" />
        <meta
          name="og:title"
          content="Ask My Book: The Minimalist Entrepreneur"
        />
        <meta
          name="og:description"
          content="Ask questions of my book, get answers in my voice, powered by AI"
        />
        <meta name="og:image" content="/social.png" />
        <meta name="twitter:image:src" content="/social.png" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        {/* <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"></script> */}
      </Head>
      <Component {...pageProps} />
    </>
  );
}
