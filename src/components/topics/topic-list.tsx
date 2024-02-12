import Link from "next/link";
import { Chip } from "@nextui-org/react";
import { db } from "@/db";
import paths from "@/paths";

export async function TopicList() {
  const topics = await db.topic.findMany();
  const renderedTopics = topics.map((topic) => {
    return (
      <div key={topic.id}>
        <Link href={paths.topicShow(topic.slug)}>
          <Chip className="hover:scale-[1.05]" color="warning" variant="flat">
            {topic.slug}
          </Chip>
        </Link>
      </div>
    );
  });

  return (
    <div className="flex flex-col m-2 flex-wrap gap-2">{renderedTopics}</div>
  );
}
