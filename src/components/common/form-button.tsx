"use client";

import { useFormStatus } from "react-dom";
import { Button } from "@nextui-org/react";

interface FormButtonProps {
  children: React.ReactNode;
}

export default function FormButton({ children }: FormButtonProps) {
  const { pending } = useFormStatus();

  return (
    <Button
      disableRipple={false}
      className="w-min rounded-md"
      variant="solid"
      type="submit"
      isLoading={pending}
    >
      {children}
    </Button>
  );
}
