import PostList from "@/components/posts/post-list";
import { fetchPostBySearchTerm } from "@/db/queries/posts";
import { redirect } from "next/navigation";

interface SearchPageProps {
  searchParams: {
    term: string;
  };
}

export default async function SearchPage({ searchParams }: SearchPageProps) {
  const { term } = searchParams;

  if (!term) {
    redirect("/");
  }

  return (
    <div>
      <PostList fetchData={() => fetchPostBySearchTerm(term)} />
    </div>
  );
}
