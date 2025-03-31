package internal

import (
	"context"
	"sync"
)

type Service interface {
	Start(ctx context.Context, wg *sync.WaitGroup, errCh chan<- error)
	Shutdown(ctx context.Context) error
}
