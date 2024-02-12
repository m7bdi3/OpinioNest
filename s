You're a senior and lead web developer who specializes in Nextjs React and typeScript. your'e responsible for improving the project i'll send you pinpointing and fixing any mistakes , creating comments and a full readme for github publication. i'll start by sending you all the project files and you'll reply with a file per message and when i say next you go on with the next file till the finish of all the files and then the readme in the end. Don't reply to any files right now till i tell you to start  

remember 1 file per message and don't forget to add the comments 

you'll start by creating the readme file for github to publish immediatly . 

here's the order of the files to start with : 
first start with prisma\schema.prisma then : 

1- src\db\index.ts
2- src\auth.ts 
3- src\actions\sign-in.ts
4- src\actions\sign-out.ts
5- src\actions\index.ts 
6- src\db\queries\comments.ts
7- src\db\queries\posts.tsx
8- src\paths.ts
9- src\app\api\auth\[...nextauth]\route.ts
10 - src\app\providers.tsx
11- src\components\header-auth.tsx
12 - src\components\header.tsx
13 - src\components\profile.tsx
14-src\components\search-input.tsx
15-src\actions\create-comment.ts
16-src\actions\create-post.ts
17- src\actions\create-topic.ts
18-src\actions\search.ts
19-src\components\common\form-button.tsx
20- src\components\topics\topic-create-form.tsx
21- src\components\topics\topic-list.tsx
22-src\components\posts\post-create-form.tsx
23-src\components\posts\post-list.tsx
24-src\components\posts\post-show-loading.tsx
25-src\components\posts\post-show.tsx
26-src\components\comments\comment-create-form.tsx
27-src\components\comments\comment-list.tsx
28-src\components\comments\comment-show.tsx
29-src\app\page.tsx
30-src\app\topics\[slug]\page.tsx
31-src\app\topics\[slug]\posts\new\page.tsx
32-src\app\topics\[slug]\posts\[postId]\page.tsx
33-src\app\search\page.tsx

📦src
 ┣ 📂actions
 ┃ ┣ 📜create-comment.ts:
"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { auth } from "@/auth";
import { db } from "@/db";
import paths from "@/paths";

const createCommentSchema = z.object({
  content: z.string().min(3),
});

interface CreateCommentFormState {
  errors: {
    content?: string[];
    _form?: string[];
  };
  success?: boolean;
}

export async function createComment(
  { postId, parentId }: { postId: string; parentId?: string },
  formState: CreateCommentFormState,
  formData: FormData
): Promise<CreateCommentFormState> {
  const result = createCommentSchema.safeParse({
    content: formData.get("content"),
  });

  if (!result.success) {
    return {
      errors: result.error.flatten().fieldErrors,
    };
  }

  const session = await auth();
  if (!session || !session.user) {
    return {
      errors: {
        _form: ["You must sign in to do this."],
      },
    };
  }

  try {
    await db.comment.create({
      data: {
        content: result.data.content,
        postId: postId,
        parentId: parentId,
        userId: session.user.id,
      },
    });
  } catch (err) {
    if (err instanceof Error) {
      return {
        errors: {
          _form: [err.message],
        },
      };
    } else {
      return {
        errors: {
          _form: ["Something went wrong..."],
        },
      };
    }
  }

  const topic = await db.topic.findFirst({
    where: { posts: { some: { id: postId } } },
  });

  if (!topic) {
    return {
      errors: {
        _form: ["Failed to revalidate topic"],
      },
    };
  }

  revalidatePath(paths.postShow(topic.slug, postId));
  return {
    errors: {},
    success: true,
  };
}
 ┃ ┣ 📜create-post.ts
'use server';

import type { Post } from '@prisma/client';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { auth } from '@/auth';
import { db } from '@/db';
import paths from '@/paths';

const createPostSchema = z.object({
  title: z.string().min(3),
  content: z.string().min(10),
});

interface CreatePostFormState {
  errors: {
    title?: string[];
    content?: string[];
    _form?: string[];
  };
}

export async function createPost(
  slug: string,
  formState: CreatePostFormState,
  formData: FormData
): Promise<CreatePostFormState> {
  const result = createPostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
  });

  if (!result.success) {
    return {
      errors: result.error.flatten().fieldErrors,
    };
  }

  const session = await auth();
  if (!session || !session.user) {
    return {
      errors: {
        _form: ['You must be signed in to do this'],
      },
    };
  }

  const topic = await db.topic.findFirst({
    where: { slug },
  });

  if (!topic) {
    return {
      errors: {
        _form: ['Cannot find topic'],
      },
    };
  }

  let post: Post;
  try {
    post = await db.post.create({
      data: {
        title: result.data.title,
        content: result.data.content,
        userId: session.user.id,
        topicId: topic.id,
      },
    });
  } catch (err: unknown) {
    if (err instanceof Error) {
      return {
        errors: {
          _form: [err.message],
        },
      };
    } else {
      return {
        errors: {
          _form: ['Failed to create post'],
        },
      };
    }
  }

  revalidatePath(paths.topicShow(slug));
  redirect(paths.postShow(slug, post.id));
}
 ┃ ┣ 📜create-topic.ts
"use server";
import type { Topic } from "@prisma/client";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { z } from "zod";
import { auth } from "@/auth";
import { db } from "@/db";
import paths from "@/paths";

const createTopicSchema = z.object({
  name: z
    .string()
    .min(3)
    .regex(/^[a-z-]+$/, {
      message: "Must be Lower case letters or dashes without spaces",
    }),
  description: z.string().min(10),
});
interface CreateTopicFormState {
  errors: {
    name?: string[];
    description?: string[];
    _form?: string[];
  };
}
export async function createTopic(
  formState: CreateTopicFormState,
  formData: FormData
): Promise<CreateTopicFormState> {
  const result = createTopicSchema.safeParse({
    name: formData.get("name"),
    description: formData.get("description"),
  });

  if (!result.success) {
    return {
      errors: result.error.flatten().fieldErrors,
    };
  }

  const session = await auth();
  if (!session || !session.user) {
    return {
      errors: {
        _form: ["You must be signed in."],
      },
    };
  }

  let topic: Topic;

  try {
    topic = await db.topic.create({
      data: {
        slug: result.data.name,
        description: result.data.description,
      },
    });
  } catch (err: unknown) {
    if (err instanceof Error) {
      return {
        errors: {
          _form: [err.message],
        },
      };
    } else {
      return {
        errors: {
          _form: ["Something went wrong!"],
        },
      };
    }
  }
  revalidatePath("/");
  redirect(paths.topicShow(topic.slug));
}
 ┃ ┣ 📜index.ts
export { signIn } from "./sign-in";
export { signOut } from "./sign-out";
export { createComment } from "./create-comment";
export { createPost } from "./create-post";
export { createTopic } from "./create-topic";
export {search} from './search'
 ┃ ┣ 📜search.ts
"use server";

import {redirect } from "next/navigation";

export async function search(formData: FormData) {
  const term = formData.get("term");

  if (typeof term !== "string" || !term) {
    redirect("/");
  }
  redirect(`/search?term=${term}`);
}
 ┃ ┣ 📜sign-in.ts
'use server';

import * as auth from '@/auth';

export async function signIn() {
  return auth.signIn('github');
}
 ┃ ┗ 📜sign-out.ts
'use server';

import * as auth from '@/auth';

export async function signOut() {
  return auth.signOut();
}
 ┣ 📂app
 ┃ ┣ 📂api
 ┃ ┃ ┗ 📂auth
 ┃ ┃ ┃ ┗ 📂[...nextauth]
 ┃ ┃ ┃ ┃ ┗ 📜route.ts
export { GET, POST } from '@/auth';
 ┃ ┣ 📂search
 ┃ ┃ ┗ 📜page.tsx
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
 ┃ ┣ 📂topics
 ┃ ┃ ┗ 📂[slug]
 ┃ ┃ ┃ ┣ 📂posts
 ┃ ┃ ┃ ┃ ┣ 📂new
 ┃ ┃ ┃ ┃ ┃ ┗ 📜page.tsx
export default function PostCreatePost() {
    return <div>Post Create Page</div>
}
 ┃ ┃ ┃ ┃ ┗ 📂[postId]
 ┃ ┃ ┃ ┃ ┃ ┗ 📜page.tsx
import Link from "next/link";
import PostShow from "@/components/posts/post-show";
import CommentList from "@/components/comments/comment-list";
import CommentCreateForm from "@/components/comments/comment-create-form";
import paths from "@/paths";
import { Suspense } from "react";
import PostShowLoading from "@/components/posts/post-show-loading";
interface PostShowPageProps {
  params: {
    slug: string;
    postId: string;
  };
}

export default async function PostShowPage({ params }: PostShowPageProps) {
  const { slug, postId } = params;

  return (
    <div className="space-y-3">
      <Link className="underline decoration-solid" href={paths.topicShow(slug)}>
        {"< "}Back to {slug}
      </Link>
      <Suspense fallback={PostShowLoading()}>
      <PostShow postId={postId} />
      </Suspense>
      <CommentCreateForm postId={postId} startOpen />
      <Suspense fallback={PostShowLoading()}>
      <CommentList postId={postId} />
      </Suspense>
    </div>
  );
}
 ┃ ┃ ┃ ┗ 📜page.tsx
import PostCreateForm from '@/components/posts/post-create-form';
import PostList from '@/components/posts/post-list';
import { fetchPostsByTopicSlug } from '@/db/queries/posts';
interface TopicShowPageProps {
  params: {
    slug: string;
  };
}

export default function TopicShowPage({ params }: TopicShowPageProps) {
  const { slug } = params;

  return (
    <div className="grid grid-cols-4 gap-4 p-4">
      <div className="col-span-3">
        <h1 className="text-2xl font-bold mb-2">{slug}</h1>
        <PostList fetchData={()=> fetchPostsByTopicSlug(slug)}/>
      </div>

      <div>
        <PostCreateForm slug={slug} />
      </div>
    </div>
  );
}
 ┃ ┣ 📜globals.css
 ┃ ┣ 📜layout.tsx
 ┃ ┣ 📜page.tsx
import PostList from "@/components/posts/post-list";
import TopicCreateForm from "@/components/topics/topic-create-form";
import  {TopicList} from '@/components/topics/topic-list'
import { fetchTopPosts } from "@/db/queries/posts";
import { Divider } from "@nextui-org/react";
export default function Home() {
  return (
    <div className="grid grid-cols-4 gap-4 p-4">
      <div className="col-span-3">
        <h1 className="text-xl m-2">Top Posts</h1>
        <PostList fetchData={fetchTopPosts} />
      </div>
      <div className="border shadow py-3 px-2">
        <TopicCreateForm />
        <Divider className="my-2" />
        <h3 className="text-lg">Topics</h3>
        <TopicList />
      </div>
    </div>
  );
}
 ┃ ┗ 📜providers.tsx
"use client";

import { NextUIProvider } from "@nextui-org/react";
import { SessionProvider } from "next-auth/react";
interface ProvidersProps {
  children: React.ReactNode;
}
export default function Providers({ children }: ProvidersProps) {
  return (
    <SessionProvider>
      <NextUIProvider>{children}</NextUIProvider>
    </SessionProvider>
  );
}
 ┣ 📂components
 ┃ ┣ 📂comments
 ┃ ┃ ┣ 📜comment-create-form.tsx
"use client";

import { useFormState } from "react-dom";
import { useEffect, useRef, useState } from "react";
import { Textarea, Button } from "@nextui-org/react";
import FormButton from "@/components/common/form-button";
import * as actions from "@/actions";

interface CommentCreateFormProps {
  postId: string;
  parentId?: string;
  startOpen?: boolean;
}

export default function CommentCreateForm({
  postId,
  parentId,
  startOpen,
}: CommentCreateFormProps) {
  const [open, setOpen] = useState(startOpen);
  const ref = useRef<HTMLFormElement | null>(null);
  const [formState, action] = useFormState(
    actions.createComment.bind(null, { postId, parentId }),
    { errors: {} }
  );

  useEffect(() => {
    if (formState.success) {
      ref.current?.reset();

      if (!startOpen) {
        setOpen(false);
      }
    }
  }, [formState, startOpen]);

  const form = (
    <form action={action} ref={ref}>
      <div className="space-y-2 px-1">
        <Textarea
          name="content"
          label="Reply"
          labelPlacement="inside"
          placeholder="Enter your comment"
          isInvalid={!!formState.errors.content}
          errorMessage={formState.errors.content?.join(", ")}
        />

        {formState.errors._form ? (
          <div className="p-2 bg-red-200 border rounded border-red-400">
            {formState.errors._form?.join(", ")}
          </div>
        ) : null}

        <FormButton>Create Comment</FormButton>
      </div>
    </form>
  );

  return (
    <div>
      <Button size="sm" variant="faded" onClick={() => setOpen(!open)}>
        Reply
      </Button>
      {open && form}
    </div>
  );
}
 ┃ ┃ ┣ 📜comment-list.tsx
import CommentShow from "@/components/comments/comment-show";
import { CommentWithAuthor, fetchCommentByPostId } from "@/db/queries/comments";

interface CommentListProps {
postId : string
}

export default async function CommentList({postId}: CommentListProps) {
  await new Promise((resolve) => setTimeout(resolve, 2500));
const comments= await fetchCommentByPostId(postId)

  const topLevelComments = comments.filter(
    (comment) => comment.parentId === null
  );
  const renderedComments = topLevelComments.map((comment) => {
    return (
      <CommentShow
        key={comment.id}
        commentId={comment.id}
        postId={postId}
      />
    );
  });

  return (
    <div className="space-y-3">
      <h1 className="text-lg font-bold">All {comments.length} comments</h1>
      {renderedComments}
    </div>
  );
}
 ┃ ┃ ┗ 📜comment-show.tsx
import Image from "next/image";
import { Button } from "@nextui-org/react";
import CommentCreateForm from "@/components/comments/comment-create-form";
import { fetchCommentByPostId } from "@/db/queries/comments";

interface CommentShowProps {
  commentId: string;
  postId: string;
}

export default async function CommentShow({
  commentId,
  postId,
}: CommentShowProps) {
  const comments = await fetchCommentByPostId(postId);
  const comment = comments.find((c) => c.id === commentId);

  if (!comment) {
    return null;
  }

  const children = comments.filter((c) => c.parentId === commentId);
  const renderedChildren = children.map((child) => {
    return <CommentShow key={child.id} commentId={child.id} postId={postId} />;
  });

  return (
    <div className="p-4 border mt-2 mb-1">
      <div className="flex gap-3">
        <Image
          src={comment.user.image || ""}
          alt="user image"
          width={40}
          height={40}
          className="w-10 h-10 rounded-full"
        />
        <div className="flex-1 space-y-3">
          <p className="text-sm font-medium text-gray-500">
            {comment.user.name}
          </p>
          <p className="text-gray-900">{comment.content}</p>

          <CommentCreateForm postId={comment.postId} parentId={comment.id} />
        </div>
      </div>
      <div className="pl-4">{renderedChildren}</div>
    </div>
  );
}
 ┃ ┣ 📂common
 ┃ ┃ ┗ 📜form-button.tsx
'use client';

import { useFormStatus } from 'react-dom';
import { Button } from '@nextui-org/react';

interface FormButtonProps {
  children: React.ReactNode;
}

export default function FormButton({ children }: FormButtonProps) {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" isLoading={pending}>
      {children}
    </Button>
  );
}
 ┃ ┣ 📂posts
 ┃ ┃ ┣ 📜post-create-form.tsx
'use client';

import { useFormState } from 'react-dom';
import {
  Input,
  Button,
  Textarea,
  Popover,
  PopoverTrigger,
  PopoverContent,
} from '@nextui-org/react';
import * as actions from '@/actions';
import FormButton from '@/components/common/form-button';

interface PostCreateFormProps {
  slug: string;
}

export default function PostCreateForm({ slug }: PostCreateFormProps) {
  const [formState, action] = useFormState(
    actions.createPost.bind(null, slug),
    {
      errors: {},
    }
  );

  return (
    <Popover placement="left">
      <PopoverTrigger>
        <Button color="primary">Create a Post</Button>
      </PopoverTrigger>
      <PopoverContent>
        <form action={action}>
          <div className="flex flex-col gap-4 p-4 w-80">
            <h3 className="text-lg">Create a Post</h3>

            <Input
              isInvalid={!!formState.errors.title}
              errorMessage={formState.errors.title?.join(', ')}
              name="title"
              label="Title"
              labelPlacement="outside"
              placeholder="Title"
            />
            <Textarea
              isInvalid={!!formState.errors.content}
              errorMessage={formState.errors.content?.join(', ')}
              name="content"
              label="Content"
              labelPlacement="outside"
              placeholder="Content"
            />

            {formState.errors._form ? (
              <div className="rounded p-2 bg-red-200 border border-red-400">
                {formState.errors._form.join(', ')}
              </div>
            ) : null}

            <FormButton>Create Post</FormButton>
          </div>
        </form>
      </PopoverContent>
    </Popover>
  );
}
 ┃ ┃ ┣ 📜post-list.tsx
import type { PostWithData } from "@/db/queries/posts";
import Link from "next/link";
import paths from "@/paths";

interface PostListProps {
  fetchData: () => Promise<PostWithData[]>;
}

export default async function PostList({ fetchData }: PostListProps) {
  const posts =await fetchData()
  const renderedPosts = posts.map((post) => {
    const topicSlug = post.topic.slug;

    if (!topicSlug) {
      throw new Error("Need a slug to link to a post");
    }

    return (
      <div key={post.id} className="border rounded p-2">
        <Link href={paths.postShow(topicSlug, post.id)}>
          <h3 className="text-lg font-bold">{post.title}</h3>
          <div className="flex flex-row gap-8">
            <p className="text-xs text-gray-400">By {post.user.name}</p>
            <p className="text-xs text-gray-400">
              {post._count.comments} comments
            </p>
          </div>
        </Link>
      </div>
    );
  });

  return <div className="space-y-2">{renderedPosts}</div>;
}
 ┃ ┃ ┣ 📜post-show-loading.tsx
import { Skeleton } from "@nextui-org/react";

export default function PostShowLoading() {
  return (
    <div className="m-4">
      <div className="my-2">
        <Skeleton className="h-8 w-48" />
      </div>
      <div className="p-4 border rounded space-y-2">
        <Skeleton className="h-6 w-32" />
        <Skeleton className="h-6 w-32" />
        <Skeleton className="h-6 w-32" />
      </div>
    </div>
  );
}
 ┃ ┃ ┗ 📜post-show.tsx
import { db } from "@/db";
import { notFound } from "next/navigation";

interface PostShowProps {
  postId: string;
}

export default async function PostShow({ postId }: PostShowProps) {
  await new Promise((resolve) => setTimeout(resolve, 2500));
  const post = await db.post.findFirst({
    where: { id: postId },
  });

  if (!post) {
    notFound();
  }
  return (
    <div className="m-4">
      <h1 className="text-2xl font-bold my-2">{post.title}</h1>
      <p className="p-4 border rounded">{post.content}</p>
    </div>
  );
}
 ┃ ┣ 📂topics
 ┃ ┃ ┣ 📜topic-create-form.tsx
"use client";
import { useFormState } from "react-dom";
import {
  Input,
  Button,
  Textarea,
  Popover,
  PopoverTrigger,
  PopoverContent,
} from "@nextui-org/react";
import * as actions from "@/actions";
import FormButton from "../common/form-button";


export default function TopicCreateForm() {
  const [formState, action] = useFormState(actions.createTopic, {
    errors: {},
  });

  return (
    <Popover placement="left">
      <PopoverTrigger>
        <Button color="primary">Create a topic</Button>
      </PopoverTrigger>
      <PopoverContent>
        <form action={action}>
          <div className="flex flex-col gap-4 p-4 w-80">
            <h3 className="text-lg">Create a Topic</h3>
            <Input
              name="name"
              label="Name"
              labelPlacement="outside"
              placeholder="Name"
              isInvalid={!!formState.errors.name}
              errorMessage={formState.errors.name?.join(", ")}
            />
            <Textarea
              name="description"
              label="Description"
              labelPlacement="outside"
              placeholder="Descripe your topic"
              isInvalid={!!formState.errors.description}
              errorMessage={formState.errors.description?.join(", ")}
            />

            {formState.errors._form ? (
              <div className="p-2 bg-red-200 border rounded-lg border-red-200">
                {formState.errors._form?.join(", ")}
              </div>
            ) : null}

            <FormButton>Submit</FormButton>
          </div>
        </form>
      </PopoverContent>
    </Popover>
  );
}
 ┃ ┃ ┗ 📜topic-list.tsx
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
          <Chip color="warning" variant="shadow">
            {topic.slug}
          </Chip>
        </Link>
      </div>
    );
  });

  return <div className="flex flex-row flex-wrap gap-2">{renderedTopics}</div>;
}
 ┃ ┣ 📜header.tsx
import Link from "next/link";
import {
  Navbar,
  NavbarBrand,
  NavbarContent,
  NavbarItem,
} from "@nextui-org/react";
import HeaderAuth from "./header-auth";
import SearchInput from "./search-input";
import { Suspense } from "react";
export default function Header() {
  return (
    <Navbar className="shadow mb-6">
      <NavbarBrand>
        <Link href="/" className="font-bold">
          Discuss
        </Link>
      </NavbarBrand>
      <NavbarContent justify="center">
        <NavbarItem>
          <Suspense>
            <SearchInput />
          </Suspense>
        </NavbarItem>
      </NavbarContent>
      <NavbarContent justify="end">
        <HeaderAuth />
      </NavbarContent>
    </Navbar>
  );
}
 ┃ ┣ 📜header-auth.tsx
'use client';

import {
  NavbarItem,
  Button,
  Avatar,
  Popover,
  PopoverTrigger,
  PopoverContent,
} from '@nextui-org/react';
import { useSession } from 'next-auth/react';
import * as actions from '@/actions';

export default function HeaderAuth() {
  const session = useSession();

  let authContent: React.ReactNode;
  if (session.status === 'loading') {
    authContent = null;
  } else if (session.data?.user) {
    authContent = (
      <Popover placement="left">
        <PopoverTrigger>
          <Avatar src={session.data.user.image || ''} />
        </PopoverTrigger>
        <PopoverContent>
          <div className="p-4">
            <form action={actions.signOut}>
              <Button type="submit">Sign Out</Button>
            </form>
          </div>
        </PopoverContent>
      </Popover>
    );
  } else {
    authContent = (
      <>
        <NavbarItem>
          <form action={actions.signIn}>
            <Button type="submit" color="secondary" variant="bordered">
              Sign In
            </Button>
          </form>
        </NavbarItem>

        <NavbarItem>
          <form action={actions.signIn}>
            <Button type="submit" color="primary" variant="flat">
              Sign Up
            </Button>
          </form>
        </NavbarItem>
      </>
    );
  }

  return authContent;
}
 ┃ ┣ 📜profile.tsx
"use client";
import { useSession } from "next-auth/react";

export default function Profile() {
  const session = useSession();

  if (session.data?.user) {
    return <div>From Client: {JSON.stringify(session.data.user)} </div>;
  } else {
    return <div>From Client: User is signed out</div>;
  }
}
 ┃ ┗ 📜search-input.tsx
"use client";

import { Input } from "@nextui-org/react";
import { useSearchParams } from "next/navigation";
import * as actions from "@/actions";

export default function SearchInput() {
  const searchParams = useSearchParams();
  return (
    <form action={actions.search}>
      <Input name="term" defaultValue={searchParams.get("term") || ""} />
    </form>
  );
}
 ┣ 📂db
 ┃ ┣ 📂queries
 ┃ ┃ ┣ 📜comments.ts
import type { Comment } from "@prisma/client";
import { db } from "@/db";
import { cache } from "react";

export type CommentWithAuthor = Comment & {
  user: { name: string | null; image: string | null };
};

export const fetchCommentByPostId = cache(
  (postId: string): Promise<CommentWithAuthor[]> => {
    console.log("making a query");
    return db.comment.findMany({
      where: { postId },
      include: {
        user: {
          select: {
            name: true,
            image: true,
          },
        },
      },
    });
  }
);
 ┃ ┃ ┗ 📜posts.tsx
import type { Post } from "@prisma/client";
import { db } from "..";

export type PostWithData = Post & {
  topic: { slug: string };
  user: { name: string | null };
  _count: { comments: number };
};

export function fetchPostsByTopicSlug(slug: string): Promise<PostWithData[]> {
  return db.post.findMany({
    where: { topic: { slug } },
    include: {
      topic: { select: { slug: true } },
      user: { select: { name: true } },
      _count: { select: { comments: true } },
    },
  });
}

export function fetchPostBySearchTerm(term: string): Promise<PostWithData[]> {
  return db.post.findMany({
    include: {
      topic: { select: { slug: true } },
      user: { select: { name: true } },
      _count: { select: { comments: true } },
    },
    where: {
      OR: [{ title: { contains: term } }, { content: { contains: term } },],
    },
  });
}

export function fetchTopPosts(): Promise<PostWithData[]> {
  return db.post.findMany({
    orderBy: [
      {
        comments: {
          _count: "desc",
        },
      },
    ],
    include: {
      topic: { select: { slug: true } },
      user: { select: { name: true, image: true } },
      _count: { select: { comments: true } },
    },
    take: 5,
  });
}
 ┃ ┗ 📜index.ts
import {PrismaClient} from '@prisma/client';

export const db= new PrismaClient();
 ┣ 📜auth.ts
import NextAuth from "next-auth";
import Github from "next-auth/providers/github";
import { PrismaAdapter } from "@auth/prisma-adapter";
import { db } from "@/db";

// Environment variables for GitHub OAuth credentials
const GITHUB_CLIENT_ID = process.env.GITHUB_CLIENT_ID;
const GITHUB_CLIENT_SECRET = process.env.GITHUB_CLIENT_SECRET;

// Check if GitHub OAuth credentials are set, if not throw an error
if (!GITHUB_CLIENT_ID || !GITHUB_CLIENT_SECRET) {
  throw new Error("Missing GitHub OAuth credentials");
}

// Export the NextAuth handlers and functions
export const {
  handlers: { GET, POST }, // HTTP methods for authentication routes
  auth,                     // Authentication middleware for API routes
  signOut,                  // Sign out function
  signIn,                   // Sign in function
} = NextAuth({
  adapter: PrismaAdapter(db), // Use PrismaAdapter to integrate with the Prisma database
  providers: [
    Github({
      clientId: GITHUB_CLIENT_ID,      // GitHub client ID for OAuth
      clientSecret: GITHUB_CLIENT_SECRET, // GitHub client secret for OAuth
    }),
  ],
  callbacks: {
    // Callback function to fix a bug in NextAuth by adding user ID to the session
    async session({ session, user }: any) {
      if (session && user) {
        session.user.id = user.id; // Add the user ID to the session object
      }
      return session;
    },
  },
});
 ┗ 📜paths.ts
const paths = {
  home() {
    return '/';
  },
  topicShow(topicSlug: string) {
    return `/topics/${topicSlug}`;
  },
  postCreate(topicSlug: string) {
    return `/topics/${topicSlug}/posts/new`;
  },
  postShow(topicSlug: string, postId: string) {
    return `/topics/${topicSlug}/posts/${postId}`;
  },
};

export default paths;
📦prisma
 ┣ 📜dev.db
 ┣ 📜migration.sql
 ┣ 📜migration_lock.toml
 ┗ 📜schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String?
  access_token      String?
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String?
  session_state     String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model User {
  id            String    @id @default(cuid())
  name          String?
  email         String?   @unique
  emailVerified DateTime?
  image         String?
  accounts      Account[]
  sessions      Session[]
  Post          Post[]
  Comment       Comment[]
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime

  @@unique([identifier, token])
}

model Topic {
  id          String @id @default(cuid())
  slug        String @unique
  description String
  posts       Post[]

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id      String @id @default(cuid())
  title   String
  content String
  userId  String
  topicId String

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  user     User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  topic    Topic     @relation(fields: [topicId], references: [id])
  comments Comment[]
}

model Comment {
  id       String  @id @default(cuid())
  content  String
  postId   String
  userId   String
  parentId String?

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  parent   Comment?  @relation("Comments", fields: [parentId], references: [id], onDelete: Cascade)
  post     Post      @relation(fields: [postId], references: [id], onDelete: Cascade)
  user     User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  children Comment[] @relation("Comments")
}


