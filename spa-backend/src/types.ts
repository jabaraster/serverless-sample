export type Status = "Waiting" | "Uploaded";

export interface IPhotoMeta {
    photoId: string;
    size: number;
    status: Status;
    timestamp: number;
    type: string;
}