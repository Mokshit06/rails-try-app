import { Question } from '@/components/question';
import { GetServerSidePropsContext } from 'next';

type QuestionViewProps = {
  data: {
    default_question: string;
    answer: string;
    audio_src_url: string;
  };
};

export default function QuestionView({ data }: QuestionViewProps) {
  return (
    <Question
      defaultQuestion={data.default_question}
      defaultAnswer={data.answer}
      audioSrcUrl={data.audio_src_url}
    />
  );
}

export const getServerSideProps = async (ctx: GetServerSidePropsContext) => {
  const res = await fetch(`http://localhost:5000/question/${ctx.params!.id}`, {
    method: 'get',
  });
  const data = await res.json();

  return { props: { data } };
};
