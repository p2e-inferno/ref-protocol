import Link from "next/link";
import type { NextPage } from "next";
import { MetaHeader } from "~~/components/MetaHeader";

const Home: NextPage = () => {
  const readMeLink = "https://github.com/p2e-inferno/ref-protocol/blob/main/README.md"
  return (
    <>
      <MetaHeader />
      <div className="pt-12">
        <div className="px-5 flex flex-col justify-center items-center text-center">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mt-32 mb-16">Welcome to</span>
            <span className="block text-4xl font-bold my-8">Ref Protocol</span>
          </h1>
            <p>🚧 UI under construction, More coming soon...</p>
          <div className="py-16 flex justify-between w-96">
            <Link href={readMeLink}>See readme 📖</Link>
            <Link href="/debug-diamond">Tinker ⚙️</Link>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
